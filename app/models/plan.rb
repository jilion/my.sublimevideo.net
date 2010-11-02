class Plan < ActiveRecord::Base
  
  # attr_accessible ...
  
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
  
  validates :name,          :presence => true
  validates :term_type,     :presence => true
  validates :player_hits,   :presence => true
  validates :price,         :presence => true
  validates :overage_price, :presence => true
  
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
#  term_type     :string(255)
#  player_hits   :integer
#  price         :integer
#  overage_price :integer
#  created_at    :datetime
#  updated_at    :datetime
#
