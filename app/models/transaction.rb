class Transaction < ActiveRecord::Base

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

  before_create :reject_paid_invoices, :set_user_id, :set_cc_infos, :set_amount

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :unprocessed do
    event(:succeed) { transition :unprocessed => :paid }
    event(:fail)    { transition :unprocessed => :failed }

    after_transition :on => [:succeed, :fail], :do => :update_invoices
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
  
  def self.charge_by_invoice_ids(invoice_ids)
    invoices = Invoice.where(id: invoice_ids)
    transaction = new(invoices: invoices)
    transaction.save!
    
    payment = begin
      options = { order_id: transaction.id, currency: 'USD', description: transaction.order_description, flag_3ds: true }
      Ogone.purchase(transaction.amount, transaction.user.credit_card_alias, options)
    rescue => ex
      Notify.send("Charging failed: #{ex.message}", exception: ex)
      transaction.error = ex.message
      nil
    end

    # @payment && (@payment.success? || @payment.params["NCERROR"] == "50001113")
    # 50001113: orderID already processed with success
    # since a transaction is never retried, we should never get this NCERROR code...
    
    case payment.params["STATUS"].to_i
    when 9 # The payment has been accepted.
      transaction.succeed
    when 46 # Waiting for identification)
      transaction.error = payment.params["HTML_ANSWER"]
      transaction.auth_needed
    else # Something went wrong
      transaction.error = payment.params["NCERRORPLUS"] if payment
      transaction.fail
    end

    transaction
  end
    
  # ====================
  # = Instance Methods =
  # ====================

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
  def set_user_id
    self.user_id = invoices.first.user.id
  end
  def set_cc_infos
    self.cc_type        = user.cc_type
    self.cc_last_digits = user.cc_last_digits
    self.cc_expire_on   = user.cc_expire_on
  end
  def set_amount
    self.amount = invoices.map(&:amount).sum
  end

  # after_transition :on => [:succeed, :fail]
  def update_invoices
    Invoice.where(id: invoice_ids).update_all(:state => state, :"#{state}_at" => updated_at)
  end
  
  def order_description
    "SublimeVideo: " + invoices.map { |invoice| "Invoice ##{invoice.reference}" }.join(',')
  end

end



# == Schema Information
#
# Table name: transactions
#
#  id             :integer         not null, primary key
#  user_id        :integer
#  cc_type        :string(255)
#  cc_last_digits :integer
#  cc_expire_on   :date
#  state          :string(255)
#  amount         :integer
#  error          :text
#  created_at     :datetime
#  updated_at     :datetime
#

