require 'findable_and_cached'

class Addon < ActiveRecord::Base
  include FindableAndCached

  belongs_to :parent_addon, class_name: 'Addon'
  has_many :plans, class_name: 'AddonPlan'
  has_many :plugins, class_name: 'App::Plugin'
  has_many :components, through: :plugins
  has_many :sites, through: :plans

  after_save :clear_caches

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :design_dependent, inclusion: [true, false]

  scope :with_paid_plans, -> { includes(:plans).merge(AddonPlan.paid).references(:addon_plans) }
  scope :visible,         -> { includes(:plans).merge(AddonPlan.visible).references(:addon_plans) }
  scope :not_custom,      -> { includes(:plans).merge(AddonPlan.not_custom).references(:addon_plans) }

  def free_plan
    plans.free.first
  end

  def title
    I18n.t("addons.#{name}")
  end

  def to_param
    name
  end
end

# == Schema Information
#
# Table name: addons
#
#  created_at       :datetime
#  design_dependent :boolean          default(TRUE), not null
#  id               :integer          not null, primary key
#  kind             :string(255)
#  name             :string(255)      not null
#  parent_addon_id  :integer
#  updated_at       :datetime
#
# Indexes
#
#  index_addons_on_name  (name) UNIQUE
#

