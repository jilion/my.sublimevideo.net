require 'spec_helper'

describe Addons::Addonship do
  context "Factory" do
    subject { create(:addonship) }

    its(:state) { should eq 'trial' }
    its(:site)  { should be_present }
    its(:addon) { should be_present }

    it { should be_valid }
  end

  describe "Associations" do
    subject { create(:addonship) }

    it { should belong_to :site }
    it { should belong_to :addon }
  end

  describe "Validations" do
    subject { create(:addonship) }

    it { should validate_presence_of(:site_id) }
    it { should validate_presence_of(:addon_id) }

    it 'validates uniqueness of addon_id scoped by site_id' do
      site  = create(:site)
      addon = create(:addon)
      create(:addonship, site: site, addon: addon)
      addonship = build(:addonship, site: site, addon: addon)

      addonship.should_not be_valid
    end
  end

  describe "Scopes" do
    describe 'addonship scopes' do
      let(:site)   { create(:site) }
      let(:addon1) { create(:addon, category: 'logo', name: 'no-logo') }
      let(:addon2) { create(:addon, category: 'logo', name: 'custom-logo') }
      let(:addon3) { create(:addon, category: 'support', name: 'vip') }
      before do
        @addonship1 = create(:addonship, site: site, addon: addon1, state: 'paying')
        @addonship2 = create(:addonship, site: site, addon: addon2, state: 'canceled')
        @addonship3 = create(:addonship, site: site, addon: addon3, state: 'paying')
      end

      describe 'in_category' do
        it { described_class.in_category('logo').should =~ [@addonship1, @addonship2] }
      end

      describe 'except_addon_id' do
        it { described_class.except_addon_id(nil).should =~ [@addonship1, @addonship2, @addonship3] }
        it { described_class.except_addon_id(addon2.id).should =~ [@addonship1, @addonship3] }
      end
    end
  end

  describe '#out_of_trial?' do
    it { build(:addonship).should_not be_out_of_trial }
    it { build(:addonship, trial_started_on: 2.days.ago.midnight).should_not be_out_of_trial }
    it { build(:addonship, trial_started_on: BusinessModel.days_for_trial.days.ago.midnight).should be_out_of_trial }
  end

end

# == Schema Information
#
# Table name: addonships
#
#  addon_id         :integer          not null
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  site_id          :integer          not null
#  state            :string(255)      not null
#  trial_started_on :datetime
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_addonships_on_addon_id              (addon_id)
#  index_addonships_on_site_id               (site_id)
#  index_addonships_on_site_id_and_addon_id  (site_id,addon_id) UNIQUE
#  index_addonships_on_state                 (state)
#

