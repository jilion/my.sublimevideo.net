class Addon < ActiveRecord::Base
  attr_accessible :name, :design_dependent, :public_at, :parent_addon, :kind, as: :admin

  belongs_to :parent_addon, class_name: 'Addon'
  has_many :plans, class_name: 'AddonPlan'
  has_many :plugins, class_name: 'App::Plugin'
  has_many :components, through: :plugins

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :design_dependent, inclusion: [true, false]

  def self.memorized_addons
    @memorized_addons ||= {}
  end

  def self.get(name)
    memorized_addons[name] ||= where(name: name).first
  end

  def free_plan
    plans.where(price: 0).first
  end

  def beta?
    !public_at?
  end

  def title
    I18n.t("addon_plans.#{addon.name}.#{name}")
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
#  public_at        :datetime
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_addons_on_name  (name) UNIQUE
#

