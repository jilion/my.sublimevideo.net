class Addon < ActiveRecord::Base
  
  # attr_accessible ...
  
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
  
protected
  
end

# == Schema Information
#
# Table name: addons
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  term_type  :string(255)
#  price      :integer
#  created_at :datetime
#  updated_at :datetime
#
