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
    it { should belong_to :site }
    it { should belong_to :addon }
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
        it "change the state from #{initial_state} to 'beta'" do
          build(:addonship, state: initial_state).tap { |a| a.start_beta }.state.should eq 'beta'
        end
      end
    end

    describe '#start_trial' do
      %w[inactive beta].each do |initial_state|
        it "change the state from #{initial_state} to 'trial'" do
          build(:addonship, state: initial_state).tap { |a| a.start_trial }.state.should eq 'trial'
        end
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
        it "change the state from #{initial_state} to 'subscribed'" do
          build(:addonship, state: initial_state).tap { |a| a.subscribe }.state.should eq 'subscribed'
        end
      end
    end

    describe '#cancel' do
      %w[beta trial subscribed suspended sponsored].each do |initial_state|
        it "change the state from #{initial_state} to 'inactive'" do
          build(:addonship, state: initial_state).tap { |a| a.cancel }.state.should eq 'inactive'
        end
      end
    end

    describe '#suspend' do
      %w[subscribed].each do |initial_state|
        it "change the state from #{initial_state} to 'suspended'" do
          build(:addonship, state: initial_state).tap { |a| a.suspend }.state.should eq 'suspended'
        end
      end
    end

    describe '#sponsor' do
      %w[inactive beta trial subscribed suspended].each do |initial_state|
        it "change the state from #{initial_state} to 'sponsored'" do
          build(:addonship, state: initial_state).tap { |a| a.sponsor }.state.should eq 'sponsored'
        end
      end
    end
  end

  describe "Scopes", :addons do
    let(:site) { create(:site) }
    before do
      @addonship1 = create(:addonship, site: site, addon: @logo_sublime_addon, state: 'trial', trial_started_on: (30.days - 1.second).ago)
      @addonship2 = create(:addonship, site: site, addon: @logo_no_logo_addon, state: 'trial', trial_started_on: (30.days + 1.second).ago)
      @addonship3 = create(:addonship, site: site, addon: @stats_standard_addon, state: 'trial')
      @addonship4 = create(:addonship, site: site, addon: @support_standard_addon, state: 'subscribed', trial_started_on: (30.days + 1.second).ago)
      @addonship5 = create(:addonship, site: site, addon: @support_vip_addon, state: 'subscribed')
      @addonship6 = create(:addonship, site: site, addon: create(:addon, availability: 'beta'), state: 'inactive')
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

