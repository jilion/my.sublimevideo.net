require 'base64'

class Transaction < ActiveRecord::Base

  uniquify :order_id, :chars => Array('a'..'z') + Array('0'..'9'), :length => 30

  # ================
  # = Associations =
  # ================

  belongs_to :user, :autosave => false
  has_and_belongs_to_many :invoices

  # ===============
  # = Validations =
  # ===============

  validate :at_least_one_invoice, :all_invoices_belong_to_same_user

  # =============
  # = Callbacks =
  # =============

  before_save :set_fields_from_ogone_response
  before_create :reject_paid_invoices, :set_user, :set_amount

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :unprocessed do
    event(:wait_d3d) { transition :unprocessed => :waiting_d3d }
    event(:wait)     { transition :unprocessed => :waiting }
    event(:succeed)  { transition [:unprocessed, :waiting_d3d] => :paid }
    event(:fail)     { transition [:unprocessed, :waiting_d3d] => :failed }

    after_transition :on => [:succeed, :fail, :wait, :wait_d3d], :do => :update_invoices

    after_transition :on => :succeed, :do => :send_charging_succeeded_email
    after_transition :on => :fail, :do => :send_charging_failed_email
  end

  # ==========
  # = Scopes =
  # ==========

  scope :failed, where(state: 'failed')
  scope :paid, where(state: 'paid')

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
    if user = User.find(user_id)
      open_or_failed_invoices = user.invoices.open_or_failed
      charge_by_invoice_ids(open_or_failed_invoices.map(&:id)) if open_or_failed_invoices.present?
    end
  end

  def self.charge_by_invoice_ids(invoice_ids, options={})
    invoices = Invoice.where(id: invoice_ids)
    transaction = new(invoices: invoices)
    transaction.save!

    options = options.merge({
      order_id: transaction.order_id,
      description: transaction.description,
      store: transaction.user.cc_alias,
      email: transaction.user.email,
      billing_address: { zip: transaction.user.postal_code, country: Country[transaction.user.country].name },
      d3d: true,
      paramplus: "PAYMENT=TRUE"
    })
    credit_card = options.delete(:credit_card)
    payment_method = credit_card && credit_card.valid? ? credit_card : transaction.user.cc_alias
    transaction.store_cc_infos(payment_method)

    payment = begin
      Ogone.purchase(transaction.amount, payment_method, options)
    rescue => ex
      Notify.send("Charging failed: #{ex.message}", exception: ex)
      transaction.error = ex.message
      transaction.fail
      nil
    end

    payment ? transaction.process_payment_response(payment.params) : transaction
  end

  def self.refund_by_site_id(site_id)
    if site = Site.archived.where(:refunded_at.ne => nil).find_by_id(site_id)
      Transaction.paid.joins(:invoices).where(:invoices => { :site_id => site_id }).each do |transaction|
        Ogone.delay.credit(transaction.amount, "#{transaction.pay_id};SAL")
        # begin
        #   Ding.plan_removed(site.plan.title, site.plan.cycle, transaction.amount) if Rails.env.production?
        # rescue
        #   # do nothing
        # end
      end
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  # Called from Transaction.charge_by_invoice_ids and from TransactionsController#callback
  def process_payment_response(payment_params)
    @ogone_response_infos = payment_params

    case payment_params["STATUS"]

    # Waiting for identification (3-D Secure)
    # We return the HTML to render. This HTML will redirect the user to the 3-D Secure form.
    when "46"
      self.error = Base64.decode64(payment_params["HTML_ANSWER"])
      self.wait_d3d

    # STATUS == 9, Payment requested:
    #   The payment has been accepted.
    #   An authorization code is available in the field "ACCEPTANCE".
    when "9"
      self.user.apply_pending_credit_card_info if self.user.pending_credit_card?
      self.succeed

    # STATUS == 51, Authorization waiting:
    #   The authorization will be processed offline.
    #   This is the standard response if the merchant has chosen offline processing in his account configuration
    when "51"
      self.wait # add a waiting state for invoice & transaction

    # NCSTATUS == 5
    #   STATUS == 0, Invalid or incomplete:
    #     At least one of the payment data fields is invalid or missing.
    #     The NCERROR  and NCERRORPLUS  fields contains an explanation of the error
    #     (list available at https://secure.ogone.com/ncol/paymentinfos1.asp).
    #     After correcting the error, the customer can retry the authorization process.
    #
    # NCSTATUS == 3
    #   STATUS == 2, Authorization refused:
    #     The authorization has been declined by the financial institution.
    #     The customer can retry the authorization process after selecting a different payment method (or card brand).
    #   STATUS == 93, Payment refused:
    #     A technical problem arose.
    when "0", "2", "93"
      self.user.reset_pending_credit_card_info
      self.fail

    # STATUS == 52, Authorization not known; STATUS == 92, Payment uncertain:
    #   A technical problem arose during the authorization/ payment process, giving an unpredictable result.
    #   The merchant can contact the acquirer helpdesk to know the exact status of the payment or can wait until we have updated the status in our system.
    #   The customer should not retry the authorization process since the authorization/payment might already have been accepted.
    when "52", "92"
      self.wait
      Notify.send("Transaction ##{self.id} (PAYID: #{payment_params["PAYID"]}) has an uncertain state, please investigate quickly!")

    else
      self.wait
      Notify.send("Transaction unknown status: #{payment_params["STATUS"]}")
    end

    self
  end

  def waiting?
    status == 51
  end

  def invalid?
    status == 0
  end

  def refused?
    [2, 93].include?(status)
  end

  def unknown?
    [52, 92].include?(status)
  end

  def i18n_error_key
    %w[waiting invalid refused unknown].detect { |status| self.send("#{status}?") } || "failed"
  end

  def description
    @description ||= "SublimeVideo Invoices: " + self.invoices.all.map { |invoice| "##{invoice.reference}" }.join(", ")
  end

  def store_cc_infos(payment_method)
    is_cc_alias = payment_method.is_a?(String) # not cc_alias
    self.cc_type        = is_cc_alias ? self.user.cc_type : payment_method.type
    self.cc_last_digits = is_cc_alias ? self.user.cc_last_digits : payment_method.last_digits
    self.cc_expire_on   = is_cc_alias ? self.user.cc_expire_on : Time.utc(payment_method.year, payment_method.month).end_of_month.to_date
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

  # before_save
  def set_fields_from_ogone_response
    if @ogone_response_infos.present?
      self.pay_id    = @ogone_response_infos["PAYID"]
      self.nc_status = @ogone_response_infos["NCSTATUS"].to_i
      self.status    = @ogone_response_infos["STATUS"].to_i
      self.error   ||= @ogone_response_infos["NCERRORPLUS"]
    end
  end

  # before_create
  def reject_paid_invoices
    self.invoices.reject! { |invoice| invoice.paid? }
  end

  # before_create
  def set_user
    self.user = invoices.first.user unless user_id?
  end

  # before_create
  def set_amount
    self.amount = invoices.map(&:amount).sum
  end

  # after_transition :on => [:succeed, :fail, :wait, :wait_d3d]
  def update_invoices
    Invoice.where(id: invoice_ids).each do |invoice|
      case state
      when "paid"
        invoice.succeed
      when "failed"
        invoice.fail
      when "waiting", "waiting_d3d"
        invoice.wait
      end
    end
  end

  # after_transition :on => :succeed
  def send_charging_succeeded_email
    TransactionMailer.charging_succeeded(self).deliver!
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
#  order_id       :string(255)
#  state          :string(255)
#  amount         :integer
#  error          :text
#  cc_type        :string(255)
#  cc_last_digits :string(255)
#  cc_expire_on   :date
#  pay_id         :string(255)
#  nc_status      :integer
#  status         :integer
#  created_at     :datetime
#  updated_at     :datetime
#
# Indexes
#
#  index_transactions_on_order_id  (order_id) UNIQUE
#

