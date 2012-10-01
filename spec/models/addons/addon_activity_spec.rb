require 'spec_helper'

describe Addons::AddonActivity do
  context "Factory" do
    subject { create(:addon_activity) }

    its(:state)     { should eq 'subscribed' }
    its(:addonship) { should be_present }

    it { should be_valid }
  end

  describe "Associations" do
    subject { create(:addon_activity) }

    it { should belong_to :addonship }
  end

  describe "Validations" do
    subject { create(:addon_activity) }

    it { should validate_presence_of(:addonship_id) }
    it { should validate_presence_of(:state) }
  end
end

# == Schema Information
#
# Table name: addon_activities
#
#  addonship_id :integer          not null
#  created_at   :datetime         not null
#  id           :integer          not null, primary key
#  state        :string(255)      not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_addon_activities_on_addonship_id  (addonship_id)
#  index_addon_activities_on_created_at    (created_at)
#

