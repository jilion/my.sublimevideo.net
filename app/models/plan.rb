class Plan < ActiveRecord::Base
  
  OVERAGES_PLAYER_HITS = 1000
  
  attr_accessible :name, :player_hits, :price, :overage_price
  
  # ================
  # = Associations =
  # ================
  
  has_many :sites
  has_many :invoice_items, :as => :item
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates :name,          :presence => true, :uniqueness => true
  validates :player_hits,   :presence => true, :numericality => true
  validates :price,         :presence => true, :numericality => true
  validates :overage_price, :presence => true, :numericality => true
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
end

# == Schema Information
#
# Table name: plans
#
#  id            :integer         not null, primary key
#  name          :string(255)
#  player_hits   :integer
#  price         :integer
#  overage_price :integer
#  created_at    :datetime
#  updated_at    :datetime
#
# Indexes
#
#  index_plans_on_name  (name) UNIQUE
#

