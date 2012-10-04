class Site::BillableItem < ActiveRecord::Base
  self.table_name_prefix = 'site_'

  INACTIVE_STATES = %w[suspended]
  ACTIVE_STATES   = %w[beta trial subscribed sponsored]
  STATES          = INACTIVE_STATES + ACTIVE_STATES

  attr_accessible :item, :site, :state, as: :admin

  belongs_to :item, polymorphic: true
  belongs_to :site

  validates :item, :site, :state, presence: true
  validates :state, inclusion: STATES
end

# == Schema Information
#
# Table name: site_billable_items
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
#  index_site_billable_items_on_item_type_and_item_id  (item_type,item_id)
#  index_site_billable_items_on_site_id                (site_id)
#

