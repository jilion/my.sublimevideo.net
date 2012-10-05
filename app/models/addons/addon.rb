# class Addons::Addon < ActiveRecord::Base

#   AVAILABILITIES = %w[beta public custom]

#   attr_accessible nil

#   # ================
#   # = Associations =
#   # ================

#   has_many :addonships, class_name: "Addons::Addonship"
#   has_many :sites, through: :addonships

#   # ===============
#   # = Validations =
#   # ===============

#   validates :category, :name, :title, :price, :availability, presence: true
#   validates :name, uniqueness: { scope: :category }
#   validates :availability, inclusion: AVAILABILITIES

# end
