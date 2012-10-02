require 'spec_helper'

describe Addons::Addonship do
  let(:site)  { create(:site) }
  let(:addon) { create(:addon, price: 999) }

  context "Factory" do
    subject { build(:addonship) }

    its(:state) { should eq 'inactive' }
    its(:site)  { should be_present }
    its(:addon) { should be_present }

    it { should be_valid }
  end

  describe "Associations" do
    it { should belong_to(:site) }
    it { should belong_to(:addon) }
    it { should have_many(:components).through(:addon) }
  end

  describe "Validations" do
    it { should validate_presence_of(:site_id) }
    it { should validate_presence_of(:addon_id) }

    it 'validates uniqueness of addon_id scoped by site_id' do
      create(:addonship, site: site, addon: addon)
      addonship = build(:addonship, site: site, addon: addon)

      addonship.should_not be_valid
    end
  end

  describe 'State Machine' do

    describe '#start_beta' do
      %w[inactive].each do |initial_state|
        let(:addonship) { build(:addonship, state: initial_state) }

        it "change the state from #{initial_state} to 'beta'" do
          addonship.start_beta
          addonship.state.should eq 'beta'
        end

        it 'create a new Addons::AddonActivity', :focus do
          -> { addonship.start_beta }.should create_an_addon_activity.in_state('beta')
        end
      end
    end

    describe '#start_trial' do
      %w[inactive beta].each do |initial_state|
        let(:addonship) { build(:addonship, state: initial_state) }

        it "change the state from #{initial_state} to 'trial'" do
          addonship.start_trial
          addonship.state.should eq 'trial'
        end
      end

      it 'create a new Addons::AddonActivity', :focus do
        -> { addonship.start_trial }.should create_an_addon_activity.in_state('trial')
      end

      it 'sets trial_started_on if not set already' do
        addonship = build(:addonship)
        expect { addonship.start_trial }.to change(addonship, :trial_started_on)
        expect { addonship.cancel }.to_not change(addonship, :trial_started_on)
        expect { addonship.start_trial }.to_not change(addonship, :trial_started_on)
      end
    end

    describe '#subscribe' do
      %w[inactive beta trial suspended sponsored].each do |initial_state|
        let(:addonship) { build(:addonship, state: initial_state) }

        it "change the state from #{initial_state} to 'subscribed'" do
          addonship.subscribe
          addonship.state.should eq 'subscribed'
        end

        it 'create a new Addons::AddonActivity', :focus do
          -> { addonship.subscribe }.should create_an_addon_activity.in_state('subscribed')
        end
      end
    end

    describe '#cancel' do
      %w[beta trial subscribed suspended sponsored].each do |initial_state|
        let(:addonship) { build(:addonship, state: initial_state) }

        it "change the state from #{initial_state} to 'inactive'" do
          addonship.cancel
          addonship.state.should eq 'inactive'
        end

        it 'create a new Addons::AddonActivity', :focus do
          -> { addonship.cancel }.should create_an_addon_activity.in_state('inactive')
        end
      end
    end

    describe '#suspend' do
      %w[subscribed].each do |initial_state|
        let(:addonship) { build(:addonship, state: initial_state) }

        it "change the state from #{initial_state} to 'suspended'" do
          addonship.suspend
          addonship.state.should eq 'suspended'
        end

        it 'create a new Addons::AddonActivity', :focus do
          -> { addonship.suspend }.should create_an_addon_activity.in_state('suspended')
        end
      end
    end

    describe '#sponsor' do
      %w[inactive beta trial subscribed suspended].each do |initial_state|
        let(:addonship) { build(:addonship, state: initial_state) }

        it "change the state from #{initial_state} to 'sponsored'" do
          addonship.sponsor
          addonship.state.should eq 'sponsored'
        end

        it 'create a new Addons::AddonActivity', :focus do
          -> { addonship.sponsor }.should create_an_addon_activity.in_state('sponsored')
        end
      end
    end
  end

  describe "Scopes", :addons do
    let(:site) { create(:site) }
    before do
      @addonship1 = create(:trial_addonship, site: site, addon: @logo_sublime_addon, trial_started_on: (30.days - 1.second).ago)
      @addonship2 = create(:trial_addonship, site: site, addon: @logo_no_logo_addon, trial_started_on: (30.days + 1.second).ago)
      @addonship3 = create(:trial_addonship, site: site, addon: @stats_standard_addon)
      @addonship4 = create(:subscribed_addonship, site: site, addon: @support_standard_addon, trial_started_on: (30.days + 1.second).ago)
      @addonship5 = create(:subscribed_addonship, site: site, addon: @support_vip_addon)
      @addonship6 = create(:inactive_addonship, site: site, addon: create(:beta_addon))
    end

    describe '.in_category' do
      it { described_class.in_category('logo').should =~ [@addonship1, @addonship2] }
    end

    describe '.except_addon_id' do
      it { described_class.except_addon_id(nil).should =~ [@addonship1, @addonship2, @addonship3, @addonship4, @addonship5, @addonship6] }
      it { described_class.except_addon_id(@logo_no_logo_addon.id).should =~ [@addonship1, @addonship3, @addonship4, @addonship5, @addonship6] }
    end

    describe '.out_of_trial addons' do
      it { described_class.out_of_trial.should =~ [@addonship2] }
    end

    describe '.active addons' do
      it { described_class.active.should =~ [@addonship1, @addonship2, @addonship3, @addonship4, @addonship5] }
    end

    describe '.subscribed addons' do
      it { described_class.subscribed.should =~ [@addonship4, @addonship5] }
    end

    describe '.inactive addons' do
      it { described_class.inactive.should =~ [@addonship6] }
    end

    describe '.paid addons' do
      it { described_class.paid.should =~ [@addonship5] }
    end

    describe '.addon_not_beta addons' do
      it { described_class.addon_not_beta.should =~ [@addonship1, @addonship2, @addonship3, @addonship4, @addonship5] }
    end
  end

  describe '#price' do
    %w[inactive beta trial suspended sponsored].each do |state|
      it "sets the price to 0 when in the #{state} state" do
        build(:addonship, state: state).price.should eq 0
      end
    end

    %w[subscribed].each do |state|
      it "gets the addon's price when in the #{state} state" do
        build(:addonship, state: state).price.should eq 999
      end
    end
  end

  describe '#active?' do
    %w[inactive suspended].each do |state|
      it "is active when in the #{state} state" do
        build(:addonship, state: state).should_not be_active
      end
    end

    %w[beta trial subscribed sponsored].each do |state|
      it "isn't active when in the #{state} state" do
        build(:addonship, state: state).should be_active
      end
    end
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
#  index_addonships_on_site_id_and_addon_id  (site_id,addon_id) UNIQUE
#  index_addonships_on_state                 (state)
#  index_addonships_on_trial_started_on      (trial_started_on)
#

