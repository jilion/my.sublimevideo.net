require 'base64'
StateMachine::Machine.ignore_method_conflicts = true

class Transaction < ActiveRecord::Base

  uniquify :order_id, chars: Array('a'..'z') + Array('0'..'9'), length: 30

  # ================
  # = Associations =
  # ================

  belongs_to :user, autosave: false
  has_and_belongs_to_many :invoices

  # ===============
  # = Validations =
  # ===============

  validate :at_least_one_invoice, :all_invoices_belong_to_same_user

  # =============
  # = Callbacks =
  # =============

  before_save :set_fields_from_ogone_response

  before_create :reject_paid_invoices, :set_user_and_set_cc_info, :set_amount

  # =================
  # = State Machine =
  # =================

  state_machine initial: :unprocessed do
    event(:wait_d3d) { transition unprocessed: :waiting_d3d }
    event(:wait)     { transition unprocessed: :waiting }
    event(:succeed)  { transition [:unprocessed, :waiting_d3d, :waiting] => :paid }
    event(:fail)     { transition [:unprocessed, :waiting_d3d, :waiting] => :failed }

    after_transition on: [:succeed, :fail, :wait_d3d, :wait], do: :update_invoices

    after_transition on: :succeed, do: :send_charging_succeeded_email
    after_transition on: :fail, do: :send_charging_failed_email
  end

  # ==========
  # = Scopes =
  # ==========

  # state
  scope :failed, where(state: 'failed')
  scope :paid,   where(state: 'paid')

  # =================
  # = Class Methods =
  # =================

  def self.charge_invoices
    User.active.includes(:invoices).where(invoices: { state: %w[open failed] }).each do |user|
      delay(priority: 2).charge_invoices_by_user_id(user.id)
    end
  end

  def self.charge_invoices_by_user_id(user_id)
    if user = User.active.find(user_id)
      invoices = user.invoices.open_or_failed.all

      invoices.each do |invoice|
        if invoice.transactions.failed.count >= 15
          invoices.delete(invoice)

          if invoice.site.first_paid_plan_started_at?
            # disable account suspension to ensure some of our beloved users won't be suspended...
            # invoice.user.suspend! and return
            return
          else
            invoice.cancel!
            BillingMailer.too_many_charging_attempts(invoice).deliver!
          end
        end
      end

      charge_by_invoice_ids(invoices.map(&:id).sort) if invoices.any?
    end
  end

  def self.charge_by_invoice_ids(invoice_ids, options = {})
    invoices = Invoice.where(id: invoice_ids)
    transaction = new(invoices: invoices)
    transaction.save!

    options = options.merge({
      order_id: transaction.order_id,
      description: transaction.description,
      email: transaction.user.email,
      billing_address: {
        address1: transaction.user.billing_address_1,
        zip: transaction.user.billing_postal_code,
        city: transaction.user.billing_city,
        country: transaction.user.billing_country
      },
      paramplus: "PAYMENT=TRUE"
    })

    payment = begin
      Ogone.purchase(transaction.amount, transaction.user.cc_alias, options)
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
    @ogone_response_info = payment_params

    case payment_params["STATUS"]

    # STATUS == 9, Payment requested:
    #   The payment has been accepted.
    #   An authorization code is available in the field "ACCEPTANCE".
    when "9"
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
    #
    # STATUS == 46, Waiting for identification (3-D Secure):
    # THIS SHOULD NEVER HAPPEN...
    when "0", "2", "46", "93"
      self.fail

    # STATUS == 52, Authorization not known; STATUS == 92, Payment uncertain:
    #   A technical problem arose during the authorization/ payment process, giving an unpredictable result.
    #   The merchant can contact the acquirer helpdesk to know the exact status of the payment or can wait until we have updated the status in our system.
    #   The customer should not retry the authorization process since the authorization/payment might already have been accepted.
    when "52", "92"
      Notify.send("Transaction ##{self.id} (PAYID: #{payment_params["PAYID"]}) has an uncertain state, please investigate quickly!")

      self.wait

    else
      Notify.send("Transaction unknown status: #{payment_params["STATUS"]}")

      self.wait
    end

    self
  end

  def description
    @description ||= "SublimeVideo Invoices: " + self.invoices.order(:created_at).all.map { |invoice| "##{invoice.reference}" }.join(", ")
  end

private

  # validates
  def at_least_one_invoice
    self.errors.add(:base, :at_least_one_invoice) if invoices.empty?
  end

  # validates
  def all_invoices_belong_to_same_user
    if invoices.any? { |invoice| invoice.user != invoices.first.user }
      self.errors.add(:base, :all_invoices_must_belong_to_the_same_user)
    end
  end

  # before_save
  def set_fields_from_ogone_response
    if @ogone_response_info.present?
      self.pay_id    = @ogone_response_info["PAYID"]
      self.nc_status = @ogone_response_info["NCSTATUS"].to_i
      self.status    = @ogone_response_info["STATUS"].to_i
      self.error     = @ogone_response_info["NCERRORPLUS"]
    end
  end

  # before_create
  def reject_paid_invoices
    self.invoices.reject! { |invoice| invoice.paid? }
  end

  # before_create
  def set_user_and_set_cc_info
    self.user           = invoices.first.user unless user_id?
    self.cc_type        = self.user.cc_type
    self.cc_last_digits = self.user.cc_last_digits
    self.cc_expire_on   = self.user.cc_expire_on
  end

  # before_create
  def set_amount
    self.amount = invoices.map(&:amount).sum
  end

  # after_transition on: [:succeed, :fail, :wait, :wait_d3d]
  def update_invoices
    Invoice.where(id: invoice_ids).each do |invoice|
      case state
      when "paid"
        invoice.succeed
      when "failed"
        invoice.fail
      when "waiting_d3d"
        # do nothing and let the invoice in the open state (allowing the user to retry the payment after entering a valid credit card)
      when "waiting"
        invoice.wait
      end
    end
  end

  # after_transition on: :succeed
  def send_charging_succeeded_email
    BillingMailer.transaction_succeeded(self).deliver!
  end

  # after_transition on: :fail
  def send_charging_failed_email
    BillingMailer.transaction_failed(self).deliver!
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

