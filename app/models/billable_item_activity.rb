class BillableItemActivity < ActiveRecord::Base
  attr_accessible :item, :site, :state, as: :admin

  belongs_to :site
  belongs_to :item, polymorphic: true

  validates :item, :site, :state, presence: true
  validates :state, inclusion: BillableItem::STATES
end

# == Schema Information
#
# Table name: billable_item_activities
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
#  index_billable_item_activities_on_item_type_and_item_id  (item_type,item_id)
#  index_billable_item_activities_on_site_id                (site_id)
#

