class Addons::Addon < ActiveRecord::Base

  AVAILABILITIES = %w[beta public custom]

  attr_accessible nil

  # ================
  # = Associations =
  # ================

  has_many :addonships, class_name: "Addons::Addonship"

  # ===============
  # = Validations =
  # ===============

  validates :name, uniqueness: { scope: :category }
  validates :category, :name, :title, :price, :availability, presence: true
  validates :availability, inclusion: AVAILABILITIES


  def beta?
    availability == 'beta'
  end

end

# == Schema Information
#
# Table name: addons
#
#  availability :string(255)      not null
#  category     :string(255)      not null
#  created_at   :datetime         not null
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  price        :integer          not null
#  settings     :hstore
#  title        :string(255)      not null
#  updated_at   :datetime         not null
#

