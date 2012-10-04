class Billing::Activity < ActiveRecord::Base
  attr_accessible :item, :site, :state, as: :admin

  belongs_to :item, polymorphic: true
  belongs_to :site

  validates :item, :site, :state, presence: true
  validates :state, inclusion: Site::BillableItem::STATES
end

# == Schema Information
#
# Table name: billing_activities
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
#  index_billing_activities_on_item_type_and_item_id  (item_type,item_id)
#  index_billing_activities_on_site_id                (site_id)
#

