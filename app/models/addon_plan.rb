class AddonPlan < ActiveRecord::Base
  AVAILABILITIES = %w[hidden public custom]

  attr_accessible :addon, :name, :price, :availability, as: :admin

  belongs_to :addon
  has_many :components, through: :addon

  validates :addon, :name, :price, presence: true
  validates :name, uniqueness: { scope: :addon_id }
  validates :availability, inclusion: AVAILABILITIES
  validates :price, numericality: true

  scope :not_beta, -> { where{ availability != 'beta' } }
  scope :paid,     -> { not_beta.where{ price > 0 } }

  def self.get(addon_name, addon_plan_name)
    includes(:addon).where { (addon.name == addon_name) & (name == addon_plan_name) }.first
  end

  def available?(site)
    case availability
    when 'hidden'
      false
    when 'public'
      true
    when 'custom'
      site.addon_plans.where(id: id).exists?
    end
  end

  def beta?(app_design = nil)
    component = if addon.design_dependent?
      components.where{ app_plugins.app_design_id == app_design.id }.first
    else
      components.first
    end

    (component.versions.first.version =~ /[a-z]/i).present?
  end

end

# == Schema Information
#
# Table name: addon_plans
#
#  addon_id     :integer          not null
#  availability :string(255)      not null
#  created_at   :datetime         not null
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  price        :integer          not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_addon_plans_on_addon_id           (addon_id)
#  index_addon_plans_on_addon_id_and_name  (addon_id,name) UNIQUE
#

