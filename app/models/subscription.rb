class Subscription < ActiveRecord::Base
  self.abstract_class = true

  INACTIVE_STATES = %w[suspended] unless defined? INACTIVE_STATES
  ACTIVE_STATES   = %w[beta trial subscribed sponsored] unless defined? ACTIVE_STATES
  STATES          = INACTIVE_STATES + ACTIVE_STATES unless defined? STATES

  attr_accessible :item, :site, :state, as: :admin

  belongs_to :site
  belongs_to :item, polymorphic: true

  validates :item, :site, :state, presence: true

  # scopes defined on abstract class simply don't work when called from a subclass...
  def self.designs
    where(item_type: 'Design')
  end

  def self.addon_plans
    where(item_type: 'AddonPlan')
  end

  def self.beta
    where(state: 'beta')
  end

  scope :subscribed, -> { where(state: 'subscribed') }

  def self.active
    where(state: ACTIVE_STATES)
  end

  scope :paid, -> {
    where("(item_type = 'Design' AND item_id IN (?)) OR (item_type = 'AddonPlan' AND item_id IN (?))",
      Design.paid.pluck(:id), AddonPlan.paid.pluck('addon_plans.id'))
  }

  def self.with_item(design_or_addon_plan)
    where(item_type: design_or_addon_plan.class.to_s, item_id: design_or_addon_plan.id)
  end

  def self.state(state)
    where(state: state)
  end

  def item_parent_name
    item.respond_to?(:addon_name) ? item.addon_name : item.name
  end

  def free?
    item.price.zero?
  end

  private

  def item_parent_kind
    item.respond_to?(:addon_name) ? item.addon_name : 'design'
  end
end
