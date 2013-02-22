class BillableItem < ActiveRecord::Base
  include Subscription
  self.table_name = 'billable_items' # Be prepared for BillableItem renamed SubscriptionCurrent

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
      increment_librato
    end
  end

  after_destroy ->(billable_item) do
    billable_item.site.billable_item_activities.create({ item: billable_item.item, state: 'canceled' }, as: :admin)
    increment_librato(state: 'canceled')
  end

  def item_parent_name
    item.respond_to?(:addon) ? item.addon.name : item.name
  end

  private

  def item_parent_kind
    item.is_a?(App::Design) ? 'design' : item.addon.name
  end

  def free_item?
    item.price.zero?
  end

  def increment_librato(options = {})
    source = "#{free_item? ? 'free' : 'paid'}.#{item_parent_kind}-#{item.name}"
    Librato.increment "addons.#{options[:state] || state}", source: source
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

