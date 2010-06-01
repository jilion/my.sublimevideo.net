  # == Schema Information
#
# Table name: invoices
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  reference     :string(255)
#  state         :string(255)
#  charged_at    :datetime
#  started_at    :datetime
#  ended_at      :datetime
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
  
  belongs_to :user
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user,     :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    state :current
    event(:charge)   { transition :pending => :charged }
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def calculate_from_cache
    self.started_at = user.last_invoiced_at
    self.ended_at   = Time.now.utc
    self.sites      = Invoice::Sites.new(self, :from_cache => true)
  end
  
  def set_amounts
    self.sites_amount  = sites.amount
    # self.videos_amount = videos.amount
    self.amount        = sites_amount + videos_amount
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.current(user)
    Rails.cache.fetch("current_invoice_for_user_#{user.id}", :expires_in => 1.minute) do
      invoice = user.invoices.build(:state => 'current')
      invoice.calculate_from_cache
      invoice.set_amounts
      invoice
    end
  end
  
end
