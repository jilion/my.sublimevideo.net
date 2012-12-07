class BillableItem < ActiveRecord::Base
  INACTIVE_STATES = %w[suspended] unless defined? INACTIVE_STATES
  ACTIVE_STATES   = %w[beta trial subscribed sponsored] unless defined? ACTIVE_STATES
  STATES          = INACTIVE_STATES + ACTIVE_STATES unless defined? STATES

  attr_accessible :item, :site, :state, as: :admin

  belongs_to :site
  belongs_to :item, polymorphic: true

  validates :item, :site, :state, presence: true
  validates :item_id, uniqueness: { scope: [:item_type, :site_id] }
  validates :state, inclusion: STATES

  # =================
  # = State Machine =
  # =================

  state_machine do
    state *STATES.map(&:to_sym)

    event(:suspend) { transition all - [:suspended] => :suspended }
  end

  after_save ->(billable_item) do
    if billable_item.state_changed?
      billable_item.site.billable_item_activities.create({ item: billable_item.item, state: billable_item.state }, as: :admin)

      Librato.increment "addons.#{billable_item.state}", source: "#{billable_item.item_parent_kind}-#{billable_item.item.name}"
    end
  end

  after_destroy ->(billable_item) do
    billable_item.site.billable_item_activities.create({ item: billable_item.item, state: 'canceled' }, as: :admin)

    Librato.increment 'addons.canceled', source: "#{billable_item.item_parent_kind}-#{billable_item.item.name}"
  end

  # ==========
  # = Scopes =
  # ==========

  scope :app_designs, -> { where(item_type: 'App::Design') }
  scope :addon_plans, -> { where(item_type: 'AddonPlan') }
  scope :active,      -> { where { state >> ACTIVE_STATES } }
  scope :subscribed,  -> { where(state: 'subscribed') }
  scope :paid,        -> do
    where{
      ((item_type == 'App::Design') & (item_id >> App::Design.paid.pluck(:id))) |
      ((item_type == 'AddonPlan') & (item_id >> AddonPlan.joins(:addon).paid.pluck("addon_plans.id")))
    }
  end

  def active?
    ACTIVE_STATES.include?(state)
  end

  def item_parent_kind
    item.is_a?(App::Design) ? 'design' : item.addon.name
  end

end

# == Schema Information
#
# Table name: billable_items
#
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  item_id    :integer          not null
#  item_type  :string(255)      not null
#  site_id    :integer          not null
#  state      :string(255)      not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_billable_items_on_item_type_and_item_id              (item_type,item_id)
#  index_billable_items_on_item_type_and_item_id_and_site_id  (item_type,item_id,site_id) UNIQUE
#  index_billable_items_on_site_id                            (site_id)
#

