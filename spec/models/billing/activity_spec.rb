require 'spec_helper'

describe Billing::Activity do
  describe "Associations" do
    it { should belong_to :item }
    it { should belong_to :site }
  end

  describe "Validations" do
    [:item, :site, :state].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    [:item, :site, :state].each do |attr|
      it { should validate_presence_of(attr) }
    end

    it { should ensure_inclusion_of(:state).in_array(%w[beta trial subscribed sponsored suspended]) }
  end
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

