require 'spec_helper'

describe BillableItemActivity do
  describe "Associations" do
    it { should belong_to :item }
    it { should belong_to :site }
  end

  describe "Validations" do
    [:item, :site, :state].each do |attr|
      it { should validate_presence_of(attr) }
    end

    it { should ensure_inclusion_of(:state).in_array(%w[beta trial subscribed sponsored suspended canceled]) }
  end

  describe 'Scopes' do
    let!(:billable_item_activity1) { create(:billable_item_activity, created_at: Time.utc(2013, 2, 21)) }
    let!(:billable_item_activity2) { create(:billable_item_activity, created_at: Time.utc(2013, 2, 22)) }
    let!(:billable_item_activity3) { create(:billable_item_activity, created_at: Time.utc(2013, 2, 23)) }
    let!(:billable_item_activity4) { create(:billable_item_activity, created_at: Time.utc(2013, 2, 24)) }

    describe '.before' do
      it { described_class.before(Time.utc(2013, 2, 23)).should =~ [billable_item_activity1, billable_item_activity2] }
    end

    describe '.during' do
      it { described_class.during((Time.utc(2013, 2, 22)..Time.utc(2013, 2, 23))).should =~ [billable_item_activity2, billable_item_activity3] }
    end
  end

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
#  billable_item_activities_big_index                       (site_id,item_type,item_id,state,created_at)
#  index_billable_item_activities_on_item_type_and_item_id  (item_type,item_id)
#  index_billable_item_activities_on_site_id                (site_id)
#

