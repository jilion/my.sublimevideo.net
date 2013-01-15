class Addon < ActiveRecord::Base
  attr_accessible :name, :design_dependent, :parent_addon, :kind, as: :admin

  belongs_to :parent_addon, class_name: 'Addon'
  has_many :plans, class_name: 'AddonPlan'
  has_many :plugins, class_name: 'App::Plugin'
  has_many :components, through: :plugins
  has_many :sites, through: :plans

  after_save :clear_caches

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :design_dependent, inclusion: [true, false]

  scope :with_paid_plans, -> { includes(:plans).merge(AddonPlan.paid) }
  scope :visible,         -> { includes(:plans).merge(AddonPlan.visible) }
  scope :public,          -> { includes(:plans).merge(AddonPlan.public) }

  def self.find_cached_by_name(name)
    Rails.cache.fetch [self, 'find_cached_by_name', name.to_s] do
      self.where(name: name.to_s).first
    end
  end

  def free_plan
    plans.where(price: 0).first
  end

  def title
    I18n.t("addons.#{name}")
  end

  class << self
    alias_method :get, :find_cached_by_name
  end

  private

  def clear_caches
    Rails.cache.clear [self.class, 'find_cached_by_name', name]
  end
end

# == Schema Information
#
# Table name: addons
#
#  created_at       :datetime         not null
#  design_dependent :boolean          default(TRUE), not null
#  id               :integer          not null, primary key
#  kind             :string(255)
#  name             :string(255)      not null
#  parent_addon_id  :integer
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_addons_on_name  (name) UNIQUE
#

