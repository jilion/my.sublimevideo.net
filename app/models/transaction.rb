require 'base64'

class Transaction < ActiveRecord::Base

  attr_accessor :d3d_html

  # ================
  # = Associations =
  # ================

  belongs_to :user
  has_and_belongs_to_many :invoices

  # ===============
  # = Validations =
  # ===============

  validate :at_least_one_invoice, :all_invoices_belong_to_same_user

  # =============
  # = Callbacks =
  # =============

  before_create :reject_paid_invoices, :set_user, :set_cc_infos, :set_amount

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :unprocessed do
    event(:succeed)  { transition :unprocessed => :paid }
    event(:fail)     { transition :unprocessed => :failed }
    event(:wait_d3d) { transition :unprocessed => :waiting_d3d }

    before_transition :on => [:succeed, :fail], :do => :set_fields_from_ogone_response
    after_transition  :on => [:succeed, :fail], :do => :update_invoices
    
    after_transition :on => :fail, :do => :send_charging_failed_email
  end

  # ==========
  # = Scopes =
  # ==========

  scope :failed, where(state: 'failed')

  # =================
  # = Class Methods =
  # =================

  # Recurring task
  def self.delay_charge_all_open_and_failed_invoices
    unless Delayed::Job.already_delayed?('%Transaction%charge_all_open_and_failed_invoices%')
      # Invoice.create_invoices_for_billable_sites is delayed at Time.now.utc.tomorrow.change(:hour => 12)
      # So we delay this task 1 hour after (to be sure all invoices of the day are created)
      delay(:priority => 4, :run_at => Time.now.utc.tomorrow.change(:hour => 1)).charge_all_open_and_failed_invoices
    end
  end

  def self.charge_all_open_and_failed_invoices
    User.all.each do |user|
      delay(:priority => 2).charge_open_and_failed_invoices_by_user_id(user.id) if user.invoices.open_or_failed.present?
    end
    delay_charge_all_open_and_failed_invoices
  end

  def self.charge_open_and_failed_invoices_by_user_id(user_id)
    user = User.find(user_id)
    if user
      open_or_failed_invoices = user.invoices.open_or_failed
      charge_by_invoice_ids(open_or_failed_invoices.map(&:id)) if open_or_failed_invoices.present?
    end
  end

  def self.charge_by_invoice_ids(invoice_ids, options={})
    invoices = Invoice.where(id: invoice_ids)
    transaction = new(invoices: invoices, user: options.delete(:user))
    transaction.save!

    options = options.merge({
      order_id: options.delete(:order_id) || transaction.id,
      description: transaction.description,
      store: transaction.user.cc_alias,
      email: transaction.user.email,
      billing_address: { zip: transaction.user.postal_code, country: transaction.user.country },
      d3d: true,
      paramplus: "PAYMENT=TRUE&ACTION=#{options.delete(:action)}" # options[:action] is used in TransactionsController for the flash notice (if applicable)
    })
    payment = begin
      Ogone.purchase(transaction.amount, transaction.user.credit_card || transaction.user.cc_alias, options)
    rescue => ex
      Notify.send("Charging failed: #{ex.message}", exception: ex)
      transaction.error = ex.message
      transaction.fail
      nil
    end
    
    payment ? transaction.process_payment_response(payment.params) : transaction
  end

  # ====================
  # = Instance Methods =
  # ====================

  # Called from Transaction.charge_by_invoice_ids and from TransactionsController#callback
  def process_payment_response(payment_params)
    @ogone_response_infos = payment_params

    case payment_params["STATUS"]
    when "9" # Payment requested (and accepted)
      self.succeed

    when "46" # Waiting for identification (3-D Secure)
              # We return the HTML to render. This HTML will redirect the user to the 3-D Secure form.
      @d3d_html = Base64.decode64(payment_params["HTML_ANSWER"])
      self.wait_d3d

    when "0" # Credit card information invalid or incomplete
      self.error_key = "invalid"
      self.fail

    when "2" # Authorization refused
      self.error_key = "refused"
      self.fail

    when "51" # Authorization waiting (authorization will be processed offline), should never receive this status
      self.error_key = "waiting"
      self.save

    when "52", "92" # Authorization not known, Payment uncertain
      self.error_key = "unknown"
      self.save
      Notify.send("Transaction ##{self.id} (PAYID: #{payment_params["PAYID"]}) has an uncertain state, please investigate quickly!")
    end
    
    self # return self (can be useful)
  end

  def description
    @description ||= "SublimeVideo Invoices: " + self.invoices.all.map { |invoice| "##{invoice.reference}" }.join(", ")
  end

private

  # validates
  def at_least_one_invoice
    self.errors.add(:base, :at_least_one_invoice) if invoices.empty?
  end

  # validates
  def all_invoices_belong_to_same_user
    self.errors.add(:base, :all_invoices_must_belong_to_the_same_user) if invoices.any? { |invoice| invoice.user != invoices.first.user }
  end

  # before_create
  def reject_paid_invoices
    self.invoices.reject! { |invoice| invoice.paid? }
  end
  def set_user
    self.user = invoices.first.user unless user_id?
  end
  def set_cc_infos
    self.cc_type        = user.cc_type
    self.cc_last_digits = user.cc_last_digits
    self.cc_expire_on   = user.cc_expire_on
  end
  def set_amount
    self.amount = invoices.map(&:amount).sum
  end

  # before_transition :on => [:succeed, :fail]
  def set_fields_from_ogone_response
    if @ogone_response_infos.present?
      self.pay_id     = @ogone_response_infos["PAYID"]
      self.acceptance = @ogone_response_infos["ACCEPTANCE"]
      self.status     = @ogone_response_infos["STATUS"]
      self.eci        = @ogone_response_infos["ECI"]
      self.error_code = @ogone_response_infos["NCERROR"]
      self.error      = @ogone_response_infos["NCERRORPLUS"]
    end
  end

  # after_transition :on => [:succeed, :fail]
  def update_invoices
    Invoice.where(id: invoice_ids).each { |invoice| invoice.send(paid? ? :succeed : :fail) }
  end
  
  # after_transition :on => :fail
  def send_charging_failed_email
    TransactionMailer.charging_failed(self).deliver!
  end

end



# == Schema Information
#
# Table name: transactions
#
#  id             :integer         not null, primary key
#  user_id        :integer
#  cc_type        :string(255)
#  cc_last_digits :string(255)
#  cc_expire_on   :date
#  state          :string(255)
#  amount         :integer
#  error_key      :string(255)
#  pay_id         :string(255)
#  acceptance     :string(255)
#  status         :string(255)
#  eci            :string(255)
#  error_code     :string(255)
#  error          :text
#  created_at     :datetime
#  updated_at     :datetime
#

