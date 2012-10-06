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

# == Schema Information
#
# Table name: addons
#
#  context          :text             not null
#  created_at       :datetime         not null
#  design_dependent :boolean          not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_addons_on_name  (name) UNIQUE
#

