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
    event(:wait_d3d) { transition :unprocessed => :waiting_d3d }
    event(:succeed)  { transition [:unprocessed, :waiting_d3d] => :paid }
    event(:fail)     { transition [:unprocessed, :waiting_d3d] => :failed }

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

    # Waiting for identification (3-D Secure)
    # We return the HTML to render. This HTML will redirect the user to the 3-D Secure form.
    if payment_params["STATUS"] == "46"
      @d3d_html = Base64.decode64(payment_params["HTML_ANSWER"])
      self.wait_d3d

    else
      case payment_params["NCSTATUS"]
      when "0"
        # STATUS == 9, Payment requested:
        #   The payment has been accepted.
        #   An authorization code is available in the field "ACCEPTANCE".
        case payment_params["STATUS"]
        when "9"
          self.succeed

        # STATUS == 51, Authorization waiting:
        #   The authorization will be processed offline.
        #   This is the standard response if the merchant has chosen offline processing in his account configuration
        when "51"
          self.error_key = "waiting"
          self.save
        end

      # STATUS == 0, Invalid or incomplete:
      #   At least one of the payment data fields is invalid or missing.
      #   The NC ERROR  and NC ERRORPLUS  fields contains an explanation of the error
      #   (list available at https://secure.ogone.com/ncol/paymentinfos1.asp).
      #   After correcting the error, the customer can retry the authorization process.
      when "5"
        self.error_key = "invalid"
        self.fail

      # STATUS == 2, Authorization refused:
      #   The authorization has been declined by the financial institution.
      #   The customer can retry the authorization process after selecting a different payment method (or card brand).
      # STATUS == 93, Payment refused:
      #   A technical problem arose.
      when "3"
        self.error_key = "refused"
        self.fail

      # STATUS == 52, Authorization not known; STATUS == 92, Payment uncertain:
      #   A technical problem arose during the authorization/ payment process, giving an unpredictable result.
      #   The merchant can contact the acquirer helpdesk to know the exact status of the payment or can wait until we have updated the status in our system.
      #   The customer should not retry the authorization process since the authorization/payment might already have been accepted.
      when "2"
        self.error_key = "unknown"
        self.save
        Notify.send("Transaction ##{self.id} (PAYID: #{payment_params["PAYID"]}) has an uncertain state, please investigate quickly!")
      end
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
      self.pay_id        = @ogone_response_infos["PAYID"]
      self.acceptance    = @ogone_response_infos["ACCEPTANCE"]
      self.nc_status     = @ogone_response_infos["NCSTATUS"]
      self.status        = @ogone_response_infos["STATUS"]
      self.eci           = @ogone_response_infos["ECI"]
      self.nc_error      = @ogone_response_infos["NCERROR"]
      self.nc_error_plus = @ogone_response_infos["NCERRORPLUS"]
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
#  nc_status      :string(255)
#  status         :string(255)
#  eci            :string(255)
#  nc_error       :string(255)
#  nc_error_plus  :text
#  created_at     :datetime
#  updated_at     :datetime
#

