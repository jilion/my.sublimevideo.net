class BillableItemActivity < Subscription
  self.table_name = 'billable_item_activities' # Be prepared for BillableItem renamed SubscriptionHistory

  validates :state, inclusion: STATES + ['canceled']

  scope :before, ->(date)   { where("billable_item_activities.created_at < ?", date) }
  scope :during, ->(period) { where(created_at: period) }
end

# == Schema Information
#
# Table name: billable_item_activities
#
#  created_at :datetime
#  id         :integer          not null, primary key
#  item_id    :integer          not null
#  item_type  :string(255)      not null
#  site_id    :integer          not null
#  state      :string(255)      not null
#  updated_at :datetime
#
# Indexes
#
#  billable_item_activities_big_index         (site_id,item_type,item_id,state,created_at)
#  index_billable_item_activities_on_site_id  (site_id)
#

