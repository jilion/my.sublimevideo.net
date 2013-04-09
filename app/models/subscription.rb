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
  def self.app_designs
    where(item_type: 'App::Design')
  end

  def self.addon_plans
    where(item_type: 'AddonPlan')
  end

  def self.beta
    where(state: 'beta')
  end

  def self.subscribed
    where(state: 'subscribed')
  end

  def self.active
    where(state: ACTIVE_STATES)
  end

  def self.paid
    where{
      ((item_type == 'App::Design') & (item_id >> App::Design.paid.pluck(:id))) |
      ((item_type == 'AddonPlan') & (item_id >> AddonPlan.paid.pluck("addon_plans.id")))
    }
  end

  def self.with_item(design_or_addon_plan)
    where(item_type: design_or_addon_plan.class.to_s, item_id: design_or_addon_plan.id)
  end

  def self.state(state)
    where(state: state)
  end

  def item_parent_name
    item.respond_to?(:addon) ? item.addon.name : item.name
  end

  def free?
    item.price.zero?
  end

  private

  def item_parent_kind
    item.is_a?(App::Design) ? 'design' : item.addon.name
  end
end