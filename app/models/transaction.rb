class Transaction < ActiveRecord::Base

  attr_accessible :cc_type, :cc_last_digits, :cc_expire_on, :amount

  # ================
  # = Associations =
  # ================

  belongs_to :user
  has_and_belongs_to_many :invoices

  # ===============
  # = Validations =
  # ===============

  validates :user,           :presence => true
  validates :cc_type,        :presence => true
  validates :cc_last_digits, :presence => true, :numericality => true
  validates :cc_expire_on,   :presence => true
  validates :amount,         :presence => true, :numericality => true

  validate :at_least_one_invoice

  # ==========
  # = Scopes =
  # ==========

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :open do
    event(:succeed) { transition :open => :paid }
    event(:fail)    { transition :open => :failed }
    
    after_transition :on => [:succeed, :fail], :do => :update_invoices
  end

  # =================
  # = Class Methods =
  # =================

  def self.charge(transaction_id)
    transaction = find(transaction_id)
    return if transaction.paid?

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
  end

private

  def update_invoices    
    Invoice.update_all({ :state => state, :"#{state}_at" => updated_at }, { :id => invoice_ids })
  end

  def at_least_one_invoice
    self.errors.add(:base, :at_least_one_invoice) if invoices.empty?
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

