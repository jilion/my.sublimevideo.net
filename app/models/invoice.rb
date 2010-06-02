# == Schema Information
#
# Table name: invoices
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  reference     :string(255)
#  state         :string(255)
#  charged_at    :datetime
#  started_on    :date
#  ended_on      :date
#  amount        :integer         default(0)
#  sites_amount  :integer         default(0)
#  videos_amount :integer         default(0)
#  sites         :text
#  videos        :text
#  created_at    :datetime
#  updated_at    :datetime
#

class Invoice < ActiveRecord::Base
  
  attr_accessible :state
  serialize :sites
  serialize :videos
  uniquify :reference, :chars => Array('A'..'Z') - Array('O') + Array('1'..'9')
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user, :counter_cache => true
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user,     :presence => true
  validate :validates_started_on, :validates_ended_on, :on => :create
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :set_interval_dates, :on => :create
  
  # TODO on create
  # set new user invoiced dates
  # clone current invoice sites, videos & amount (as estimation)
  # reset sites/videos caches
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    state :current
    
    event(:calculate) { transition :pending => :ready }
    event(:charge)    { transition :ready => :charged, :ready => :failed, :failed => :charged }
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def calculate_from_cache
    set_interval_dates
    self.sites = Invoice::Sites.new(self, :from_cache => true)
    # self.videos = Invoice::Videos.new(self, :from_cache => true)
    set_amounts
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.current(user)
    Rails.cache.fetch("current_invoice_for_user_#{user.id}", :expires_in => 1.minute) do
      invoice = user.invoices.build(:state => 'current')
      invoice.calculate_from_cache
      invoice
    end
  end
  
private
  
  # before_validation
  def set_interval_dates
    self.started_on = user.last_invoiced_on || user.created_at.to_date
    self.ended_on   = user.next_invoiced_on
  end
  
  def set_amounts
    self.sites_amount  = sites.amount
    # self.videos_amount = videos.amount
    self.amount        = sites_amount + videos_amount
  end
  
  # validate
  def validates_started_on
    self.errors.add(:started_on, :invalid) if started_on >= 1.month.ago.utc.to_date
  end
  
  # validate
  def validates_ended_on
    self.errors.add(:ended_on, :invalid) if ended_on >= Date.today
  end
  
end