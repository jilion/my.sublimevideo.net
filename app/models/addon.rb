class Addon < ActiveRecord::Base

  attr_accessible :name, :price

  # ================
  # = Associations =
  # ================

  has_and_belongs_to_many :sites
  has_many :invoice_items, :as => :item

  # ===============
  # = Validations =
  # ===============

  validates :name, :presence => true, :uniqueness => true
  validates :price, :presence => true, :numericality => true

end

# == Schema Information
#
# Table name: addons
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  price      :integer
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_addons_on_name  (name) UNIQUE
#
