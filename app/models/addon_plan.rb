class AddonPlan < ActiveRecord::Base
  AVAILABILITIES = %w[hidden public custom]

  attr_accessible :addon, :name, :price, :availability, :required_stage, as: :admin

  belongs_to :addon
  has_many :components, through: :addon
  has_many :billable_items, as: :item

  delegate :beta?, to: :addon

  validates :addon, :name, :price, presence: true
  validates :name, uniqueness: { scope: :addon_id }
  validates :availability, inclusion: AVAILABILITIES
  validates :required_stage, inclusion: %w[alpha beta stable]
  validates :price, numericality: true

  scope :paid, -> { includes(:addon).where{ (addon.public_at != nil) & (price > 0) } }

  def self.get(addon_name, addon_plan_name)
    includes(:addon).where { (addon.name == addon_name) & (name == addon_plan_name) }.first
  end

  def available?(site)
    case availability
    when 'hidden'
      false
    when 'public'
      addon_plan_ids_expect_myself = addon.plans.pluck(:id) - [id]
      !site.billable_items.addon_plans.where{ item_id >> addon_plan_ids_expect_myself }.where(state: 'sponsored').exists?
    when 'custom'
      site.addon_plans.where(id: id).exists?
    end
  end

  def free?
    price.zero?
  end
end

# == Schema Information
#
# Table name: addon_plans
#
#  addon_id       :integer          not null
#  availability   :string(255)      not null
#  created_at     :datetime         not null
#  id             :integer          not null, primary key
#  name           :string(255)      not null
#  price          :integer          not null
#  required_stage :string(255)      default("stable"), not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_addon_plans_on_addon_id           (addon_id)
#  index_addon_plans_on_addon_id_and_name  (addon_id,name) UNIQUE
#

