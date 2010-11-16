class Invoice < ActiveRecord::Base
  
  attr_accessible :state
  serialize :sites
  uniquify :reference, :chars => Array('A'..'Z') - ['O'] + Array('1'..'9')
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user, :counter_cache => true
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :by_charged_at, lambda { |way| order("#{Invoice.quoted_table_name}.charged_at #{way}") }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user,:presence => true
  validate :validates_started_on, :validates_ended_on, :on => :create
  validate :requires_minimun_amount, :on => :create
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :set_interval_dates, :on => :create
  before_create :clone_current_data_as_estimation
  after_create :update_user_invoiced_and_limit_alert_dates
  after_create :reset_user_sites_hits_cache
  after_create :delete_user_current_invoice_cache
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    state :current
    before_transition :on => :calculate, :do => :calculate_from_logs
    after_transition :on => :calculate, :do => :deliver_invoice_calculated_email
    
    event(:calculate) { transition :pending => :ready }
    event(:charge)    { transition :ready => :charged, :ready => :failed, :failed => :charged }
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def set_current_data
    self.state = 'current'
    set_interval_dates
    calculate_from_cache
  end
  
  def to_param
    current? ? 'current' : id
  end
  
  def include_date?(date)
    date.present? && started_on.to_date <= date.to_date && date.to_date < ended_on.to_date
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.current(user)
    Rails.cache.fetch("user_#{user.id}.current_invoice", :expires_in => 1.minute) do
      invoice = user.invoices.build
      invoice.set_current_data
      invoice
    end
  end
  
private
  
  # before_validation
  def set_interval_dates
    self.started_on = user.last_invoiced_on || user.created_at.to_date
    self.ended_on   = user.next_invoiced_on
  end
  
  # before_create
  def clone_current_data_as_estimation
    current = Invoice.current(user)
    self.sites         = current.sites
    self.sites_amount  = current.sites_amount
    self.amount        = current.amount
  end
  
  # after_create
  def update_user_invoiced_and_limit_alert_dates
    user.last_invoiced_on          = ended_on
    user.next_invoiced_on          = ended_on + 1.month
    user.limit_alert_email_sent_at = nil
    user.save
  end
  
  # after_create
  def reset_user_sites_hits_cache
    user.sites.each { |site| site.reset_hits_cache!(ended_on) }
  end
  
  # after_create
  def delete_user_current_invoice_cache
    Rails.cache.delete("user_#{user.id}.current_invoice")
  end
  
  # validate
  def validates_started_on
    self.errors.add(:started_on, :invalid) if started_on >= 1.month.ago.utc.to_date
  end
  
  # validate
  def validates_ended_on
    self.errors.add(:ended_on, :invalid) if ended_on >= Date.today
  end
  
  # validate
  def requires_minimun_amount
    if Invoice.current(user).amount < Invoice.yml[:minimum_amount]
      self.errors.add(:amount, "is too low, invoice reported to next month")
      report_user_invoice_to_next_month
    end
  end
  
  def report_user_invoice_to_next_month
    user.update_attribute(:next_invoiced_on, user.next_invoiced_on + 1.month)
  end
  
  def calculate_from_cache
    self.sites  = Invoice::Sites.new(self, :from_cache => true)
    set_amounts
  end
  
  # before_transition (calculate)
  def calculate_from_logs
    self.sites  = Invoice::Sites.new(self)
    set_amounts
  end
  
  def set_amounts
    self.sites_amount  = sites.amount
    self.amount        = sites_amount
  end
  
  # after_transition (calculate)
  def deliver_invoice_calculated_email
    InvoiceMailer.invoice_calculated(self).deliver
  end
  
  def self.yml
    config_path = Rails.root.join('config', 'invoice.yml')
    @yml ||= YAML::load_file(config_path).to_options
  rescue
    raise StandardError, "Invoice config file '#{config_path}' doesn't exist."
  end
  
end


# == Schema Information
#
# Table name: invoices
#
#  id           :integer         not null, primary key
#  user_id      :integer
#  reference    :string(255)
#  state        :string(255)
#  charged_at   :datetime
#  started_on   :date
#  ended_on     :date
#  amount       :integer(8)      default(0)
#  sites_amount :integer(8)      default(0)
#  sites        :text
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_invoices_on_user_id  (user_id)
#

