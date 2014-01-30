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
  end

  # ==========
  # = Scopes =
  # ==========

  # state
  scope :failed, -> { where(state: 'failed') }
  scope :paid,   -> { where(state: 'paid') }

  MAX_ATTEMPTS_BEFORE_SUSPEND = 15

  def description
    @description ||= invoices.map { |invoice| "##{invoice.reference}" }.join(',')
  end

  private

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

