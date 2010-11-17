class Addon < ActiveRecord::Base
  
  attr_accessible :name, :term_type
  
  # ================
  # = Associations =
  # ================
  
  has_many :invoice_items, :as => :item
  has_and_belongs_to_many :sites
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates :name,      :presence => true, :uniqueness => true
  validates :term_type, :presence => true, :inclusion => { :in => Plan::TERM_TYPES }
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
end


# == Schema Information
#
# Table name: addons
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  term_type  :string(255)
#  created_at :datetime
#  updated_at :datetime
#

