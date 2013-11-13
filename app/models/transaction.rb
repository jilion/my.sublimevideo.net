StateMachine::Machine.ignore_method_conflicts = true

class Transaction < ActiveRecord::Base
  uniquify :order_id, chars: Array('a'..'z') + Array('0'..'9'), length: 30

  # ================
  # = Associations =
  # ================

  belongs_to :user
  has_and_belongs_to_many :invoices

  # ===============
  # = Validations =
  # ===============

  validate :_at_least_one_invoice, :_all_invoices_belong_to_same_user, :_minimum_amount

  # =============
  # = Callbacks =
  # =============

  before_validation :_reject_paid_invoices, :_set_amount

  before_save :_set_fields_from_ogone_response

  before_create :_set_user_and_credit_card_info

  # =================
  # = State Machine =
  # =================

  state_machine initial: :unprocessed do
    event(:wait_d3d) { transition unprocessed: :waiting_d3d }
    event(:wait)     { transition unprocessed: :waiting }
    event(:succeed)  { transition [:unprocessed, :waiting_d3d, :waiting] => :paid }
    event(:fail)     { transition [:unprocessed, :waiting_d3d, :waiting] => :failed }

    before_transition on: [:succeed, :fail, :wait_d3d, :wait], do: [:_set_fields_from_ogone_response]
    after_transition on: [:succeed, :fail, :wait_d3d, :wait], do: [:_update_invoices]

    after_transition on: :succeed, do: :_send_charging_succeeded_email
    after_transition on: :fail, do: :_send_charging_failed_email
  end

  # ==========
  # = Scopes =
  # ==========

  # state
  scope :failed, -> { where(state: 'failed') }
  scope :paid,   -> { where(state: 'paid') }

  MAX_ATTEMPTS_BEFORE_SUSPEND = 15

  # =================
  # = Class Methods =
  # =================

  def self.charge_invoices
    User.active.uniq.joins(:invoices).merge(Invoice.open_or_failed).find_in_batches(batch_size: 100) do |users|
      now = Time.now.utc
      users.each_with_index do |user, index|
        delay(queue: 'my', at: (now + index * 5.seconds).to_i).charge_invoices_by_user_id(user.id)
      end
    end
  end

  def self.charge_invoices_by_user_id(user_id)
    return unless user = User.active.find(user_id)

    invoices = user.invoices.open_or_failed.to_a
    chargeable = invoices.any? && _suspend_user_if_needed(invoices)

    charge_by_invoice_ids(invoices.map(&:id).sort) if chargeable
  end

  def self.charge_by_invoice_ids(invoice_ids, options = {})
    transaction = new(invoices: Invoice.where(id: invoice_ids))

    if transaction.save
      if payment = transaction.execute_payment(options)
        transaction.process_payment_response(payment.params)
      end
    end

    transaction
  end

  def execute_payment(opts = {})
    begin
      OgoneWrapper.purchase(amount, user.cc_alias, _payment_options(opts))
    rescue => ex
      Notifier.send("Exception during charging: #{ex.message}", exception: ex)
      nil
    end
  end

  def self._suspend_user_if_needed(invoices)
    invoices.each do |invoice|
      if invoice.transactions.failed.count >= MAX_ATTEMPTS_BEFORE_SUSPEND
        UserManager.new(invoice.user).suspend unless invoice.user.vip?

        return false
      end
    end

    true
  end

  # ====================
  # = Instance Methods =
  # ====================

  # Called from Transaction.charge_by_invoice_ids and from TransactionsController#callback
  def process_payment_response(payment_params)
    @ogone_response_info = payment_params

    case payment_params['STATUS']

    # STATUS == 9, Payment requested:
    #   The payment has been accepted.
    #   An authorization code is available in the field "ACCEPTANCE".
    when '9'
      _process_payment_success(payment_params)

    # STATUS == 51, Authorization waiting:
    #   The authorization will be processed offline.
    #   This is the standard response if the merchant has chosen offline processing in his account configuration
    when '51'
      _process_payment_waiting(payment_params)

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
    when '0', '2', '46', '93'
      _process_payment_fail(payment_params)

    # STATUS == 52, Authorization not known; STATUS == 92, Payment uncertain:
    #   A technical problem arose during the authorization/ payment process, giving an unpredictable result.
    #   The merchant can contact the acquirer helpdesk to know the exact status of the payment or can wait until we have updated the status in our system.
    #   The customer should not retry the authorization process since the authorization/payment might already have been accepted.
    when '52', '92'
      _process_payment_uncertain(payment_params)

    else
      _process_payment_unknown(payment_params)
    end

    self
  end

  def description
    @description ||= invoices.map { |invoice| "##{invoice.reference}" }.join(',')
  end

private

  def _process_payment_success(payment_params)
    Librato.increment 'payments.success', by: payment_params['amount'].to_i, source: payment_params['BRAND']
    self.succeed
  end

  def _process_payment_waiting(payment_params)
    Librato.increment 'payments.waiting', by: payment_params['amount'].to_i, source: payment_params['BRAND']
    self.wait # add a waiting state for invoice & transaction
  end

  def _process_payment_fail(payment_params)
    Librato.increment 'payments.fail', by: payment_params['amount'].to_i, source: payment_params['BRAND']
    self.fail
  end

  def _process_payment_uncertain(payment_params)
    Librato.increment 'payments.uncertain', by: payment_params['amount'].to_i, source: payment_params['BRAND']
    Notifier.send("Transaction ##{self.id} (PAYID: #{payment_params['PAYID']}) has an uncertain state, please investigate quickly!")
    self.wait
  end

  def _process_payment_unknown(payment_params)
    Notifier.send("Transaction unknown status: #{payment_params['STATUS']}")
    self.wait
  end

  def _payment_options(options = {})
    options.merge!({
      order_id: order_id,
      description: description.to(99),
      email: user.email,
      billing_address: {
        address1: user.billing_address_1,
        zip: user.billing_postal_code,
        city: user.billing_city,
        country: user.billing_country
      },
      paramplus: 'PAYMENT=TRUE'
    })
  end

  # before_validation
  def _reject_paid_invoices
    self.invoices = invoices.reject { |invoice| invoice.paid? }
  end

  # before_validation
  def _set_amount
    self.amount = invoices.map(&:amount).sum
  end

  # validates
  def _at_least_one_invoice
    self.errors.add(:base, :at_least_one_invoice) if invoices.empty?
  end

  # validates
  def _all_invoices_belong_to_same_user
    if invoices.any? { |invoice| invoice.user != invoices.first.user }
      self.errors.add(:base, :all_invoices_must_belong_to_the_same_user)
    end
  end

  # validates
  def _minimum_amount
    self.errors.add(:amount, :minimum_amount_not_reached) if amount < 100
  end

  # before_create
  def _set_user_and_credit_card_info
    self.user           = invoices.first.user unless user_id?
    self.cc_type        = self.user.cc_type
    self.cc_last_digits = self.user.cc_last_digits
    self.cc_expire_on   = self.user.cc_expire_on
  end

  # before_transition on: [:succeed, :fail, :wait, :wait_d3d]
  def _set_fields_from_ogone_response
    if @ogone_response_info.present?
      self.pay_id    = @ogone_response_info['PAYID']
      self.nc_status = @ogone_response_info['NCSTATUS'].to_i
      self.status    = @ogone_response_info['STATUS'].to_i
      self.error     = @ogone_response_info['NCERRORPLUS']
    end
  end

  # after_transition on: [:succeed, :fail, :wait, :wait_d3d]
  def _update_invoices
    action = case state
             when 'paid'
               'succeed'
             when 'failed'
               'fail'
             when 'waiting'
               'wait'
             end

    invoices.map(&:"#{action}!") if action
  end

  # after_transition on: :succeed
  def _send_charging_succeeded_email
    BillingMailer.delay(queue: 'my').transaction_succeeded(id)
  end

  # after_transition on: :fail
  def _send_charging_failed_email
    BillingMailer.delay(queue: 'my').transaction_failed(id)
  end

end

# == Schema Information
#
# Table name: transactions
#
#  amount         :integer
#  cc_expire_on   :date
#  cc_last_digits :string(255)
#  cc_type        :string(255)
#  created_at     :datetime
#  error          :text
#  id             :integer          not null, primary key
#  nc_status      :integer
#  order_id       :string(255)
#  pay_id         :string(255)
#  state          :string(255)
#  status         :integer
#  updated_at     :datetime
#  user_id        :integer
#
# Indexes
#
#  index_transactions_on_order_id  (order_id) UNIQUE
#

