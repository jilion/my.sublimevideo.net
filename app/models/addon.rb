class Addon < ActiveRecord::Base
  attr_accessible :name, :design_dependent, :version, :context, as: :admin

  serialize :context, Array

  has_many :plans, class_name: 'AddonPlan'
  has_many :plugins, class_name: 'App::Plugin'
  has_many :components, through: :plugins

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :design_dependent, inclusion: [true, false]
  validates :version, inclusion: %w[stable beta]

  before_validation ->(addon) { addon.context = [] }, unless: :context?

  def self.get(name)
    where(name: name).first
  end

  def free_plan
    plans.where(price: 0).first
  end

  def beta?
    version == 'beta'
  end
end

# == Schema Information
#
# Table name: addons
#
#  context          :text             not null
#  created_at       :datetime         not null
#  design_dependent :boolean          default(TRUE), not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  updated_at       :datetime         not null
#  version          :string(255)      default("stable"), not null
#
# Indexes
#
#  index_addons_on_name  (name) UNIQUE
#

