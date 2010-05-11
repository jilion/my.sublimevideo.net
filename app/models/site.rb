# == Schema Information
#
# Table name: sites
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  hostname      :string(255)
#  dev_hostnames :string(255)
#  token         :string(255)
#  state         :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

class Site < ActiveRecord::Base
  
  attr_accessible :hostname, :dev_hostnames
  
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
  
  validates :user, :presence => true
  validates :hostname, :presence => true, :uniqueness => { :scope => :user_id }
  
  # =============
  # = Callbacks =
  # ==============
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    
    event :activate do
      transition :pending => :active
    end
    
    event :deactivate do
      transition :active => :pending
    end
    
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
end