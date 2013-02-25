module Subscription
  extend ActiveSupport::Concern

  included do
    INACTIVE_STATES = %w[suspended] unless defined? INACTIVE_STATES
    ACTIVE_STATES   = %w[beta trial subscribed sponsored] unless defined? ACTIVE_STATES
    STATES          = INACTIVE_STATES + ACTIVE_STATES unless defined? STATES

    attr_accessible :item, :site, :state, as: :admin

    belongs_to :site
    belongs_to :item, polymorphic: true

    validates :item, :site, :state, presence: true

    # ==========
    # = Scopes =
    # ==========

    scope :app_designs, -> { where(item_type: 'App::Design') }
    scope :addon_plans, -> { where(item_type: 'AddonPlan') }

    # States
    scope :beta,        -> { where(state: 'beta') }
    scope :subscribed,  -> { where(state: 'subscribed') }
    scope :active,      -> { where { state >> ACTIVE_STATES } }
    scope :paid,        -> do
      where{
        ((item_type == 'App::Design') & (item_id >> App::Design.paid.pluck(:id))) |
        ((item_type == 'AddonPlan') & (item_id >> AddonPlan.joins(:addon).paid.pluck("addon_plans.id")))
      }
    end
    scope :with_item, ->(design_or_addon_plan) do
      where(item_type: design_or_addon_plan.class.to_s, item_id: design_or_addon_plan.id)
    end
    scope :state, ->(state) { where(state: state) }
  end

  module ClassMethods
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