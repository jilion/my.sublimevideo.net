class Addons::Addon < ActiveRecord::Base

  AVAILABILITIES = %w[beta public custom]

  attr_accessible nil

  # ================
  # = Associations =
  # ================

  has_many :addonships, class_name: "Addons::Addonship"
  has_many :sites, through: :addonships
  has_many :componentships, class_name: "Player::Componentship"
  has_many :components, through: :componentships

  # ===============
  # = Validations =
  # ===============

  validates :category, :name, :title, :price, :availability, presence: true
  validates :name, uniqueness: { scope: :category }
  validates :availability, inclusion: AVAILABILITIES

  scope :not_beta, -> { where{ availability != 'beta' } }
  scope :paid,     -> { not_beta.where{ price > 0 } }

  def self.get(category, name)
    where(category: category, name: name).first
  end

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
# Indexes
#
#  index_addons_on_category_and_name  (category,name) UNIQUE
#

