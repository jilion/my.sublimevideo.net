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

  def self.delay_charge_unpaid_and_failed_invoices
    unless Delayed::Job.already_delayed?('%Transaction%charge_unpaid_and_failed_invoices%')
      # Invoice.create_invoices_for_billable_sites is delayed at Time.now.utc.tomorrow.change(:hour => 12)
      # So we delay this task 1 hour after (to be sure all invoices of the day are created)
      delay(:priority => 2, :run_at => Time.now.utc.tomorrow.change(:hour => 1)).charge_unpaid_and_failed_invoices
    end
  end


  def self.charge_unpaid_and_failed_invoices
    # charging implementation here
    User.each do |user|
      unpaid_or_failed_invoices = user.invoices.unpaid_or_failed
      if unpaid_or_failed_invoices.present?
        delay(:priority => 3).charge_by_invoice_ids(unpaid_or_failed_invoices.map(&:id))
      end
    end
    delay_charge_unpaid_and_failed_invoices
  end

  def self.charge_by_invoice_ids(invoice_ids)
    invoices = Invoice.where(:id => invoice_ids)
    transaction = new(:invoices => invoices)

    if transaction.save!
      @payment = begin
        Ogone.purchase(transaction.amount, transaction.user.credit_card_alias, :order_id => transaction.id, :currency => 'USD')
      rescue => ex
        Notify.send("Charging failed: #{ex.message}", :exception => ex)
        transaction.error = ex.message
        nil
      end

      if @payment && (@payment.success? || @payment.params["NCERROR"] == "50001113") # 50001113: orderID already processed with success
        transaction.succeed
      else
        transaction.error = @payment.message if @payment
        transaction.fail
      end
    else
      Notify.send("Transaction #{transaction.inspect} is not valid.")
    end

    transaction
  end

  # ====================
  # = Instance Methods =
  # ====================

private

  # =============
  # = Validates =
  # =============

  def at_least_one_invoice
    self.errors.add(:base, :at_least_one_invoice) if invoices.empty?
  end

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
    Invoice.update_all({ :state => state, :"#{state}_at" => updated_at }, { :id => invoice_ids })
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

