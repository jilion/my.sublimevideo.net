require 'spec_helper'

describe BillableItem do
  let(:site)  { create(:site) }

  describe 'Associations' do
    it { should belong_to :item }
    it { should belong_to :site }
    it { should have_many(:components).through(:item) }
  end

  describe 'Validations' do
    [:item, :site, :state].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    [:item, :site, :state].each do |attr|
      it { should validate_presence_of(attr) }
    end

    it { should ensure_inclusion_of(:state).in_array(%w[subscribed sponsored suspended]) }
  end

  context 'Factory' do
    subject { build(:addon_plan_billable_item) }

    its(:state) { should eq 'subscribed' }
    its(:site)  { should be_present }
    its(:item)  { should be_present }

    it { should be_valid }
  end

  # describe 'State Machine' do

  #   describe '#start_beta' do
  #     %w[inactive].each do |initial_state|
  #       let(:addonship) { build(:addonship, state: initial_state) }

  #       it "change the state from #{initial_state} to 'beta'" do
  #         addonship.start_beta
  #         addonship.state.should eq 'beta'
  #       end

  #       it 'create a new Addons::AddonActivity' do
  #         -> { addonship.start_beta }.should create_an_addon_activity.in_state('beta')
  #       end
  #     end
  #   end

  #   describe '#start_trial' do
  #     %w[inactive beta].each do |initial_state|
  #       let(:addonship) { build(:addonship, state: initial_state) }

  #       it "change the state from #{initial_state} to 'trial'" do
  #         addonship.start_trial
  #         addonship.state.should eq 'trial'
  #       end
  #     end

  #     it 'create a new Addons::AddonActivity' do
  #       -> { addonship.start_trial }.should create_an_addon_activity.in_state('trial')
  #     end

  #     it 'sets trial_started_on if not set already' do
  #       addonship = build(:addonship)
  #       expect { addonship.start_trial }.to change(addonship, :trial_started_on)
  #       expect { addonship.cancel }.to_not change(addonship, :trial_started_on)
  #       expect { addonship.start_trial }.to_not change(addonship, :trial_started_on)
  #     end
  #   end

  #   describe '#subscribe' do
  #     %w[inactive beta trial suspended sponsored].each do |initial_state|
  #       let(:addonship) { build(:addonship, state: initial_state) }

  #       it "change the state from #{initial_state} to 'subscribed'" do
  #         addonship.subscribe
  #         addonship.state.should eq 'subscribed'
  #       end

  #       it 'create a new Addons::AddonActivity' do
  #         -> { addonship.subscribe }.should create_an_addon_activity.in_state('subscribed')
  #       end
  #     end
  #   end

  #   describe '#cancel' do
  #     %w[beta trial subscribed suspended sponsored].each do |initial_state|
  #       let(:addonship) { build(:addonship, state: initial_state) }

  #       it "change the state from #{initial_state} to 'inactive'" do
  #         addonship.cancel
  #         addonship.state.should eq 'inactive'
  #       end

  #       it 'create a new Addons::AddonActivity' do
  #         -> { addonship.cancel }.should create_an_addon_activity.in_state('inactive')
  #       end
  #     end
  #   end

  #   describe '#suspend' do
  #     %w[subscribed].each do |initial_state|
  #       let(:addonship) { build(:addonship, state: initial_state) }

  #       it "change the state from #{initial_state} to 'suspended'" do
  #         addonship.suspend
  #         addonship.state.should eq 'suspended'
  #       end

  #       it 'create a new Addons::AddonActivity' do
  #         -> { addonship.suspend }.should create_an_addon_activity.in_state('suspended')
  #       end
  #     end
  #   end

  #   describe '#sponsor' do
  #     %w[inactive beta trial subscribed suspended].each do |initial_state|
  #       let(:addonship) { build(:addonship, state: initial_state) }

  #       it "change the state from #{initial_state} to 'sponsored'" do
  #         addonship.sponsor
  #         addonship.state.should eq 'sponsored'
  #       end

  #       it 'create a new Addons::AddonActivity' do
  #         -> { addonship.sponsor }.should create_an_addon_activity.in_state('sponsored')
  #       end
  #     end
  #   end
  # end

  describe 'Scopes', :addons do
    let(:site) { create(:site) }
    before do
      @billable_item1 = create(:billable_item, site: site, item: @logo_addon_plan_1, state: 'subscribed')
      @billable_item2 = create(:billable_item, site: site, item: @logo_addon_plan_2, state: 'subscribed')
      @billable_item3 = create(:billable_item, site: site, item: @stats_addon_plan_1, state: 'sponsored')
      @billable_item4 = create(:billable_item, site: site, item: @support_addon_plan_2, state: 'suspended')
    end

    pending '.except_addon_ids' do
      it { described_class.except_addon_ids(nil).should =~ [@billable_item1, @billable_item2, @billable_item3, @billable_item4, @billable_item5, @billable_item6] }
      it { described_class.except_addon_ids(@logo_addon_2.id).should =~ [@billable_item1, @billable_item3, @billable_item4, @billable_item5] }
    end

    pending '.out_of_trial addons' do
      it { described_class.out_of_trial.should =~ [@billable_item2] }
    end

    describe '.active addons' do
      it { described_class.active.should =~ [@billable_item1, @billable_item2, @billable_item3] }
    end

    describe '.subscribed addons' do
      it { described_class.subscribed.should =~ [@billable_item1, @billable_item2] }
    end

    describe '.paid addons' do
      it { described_class.paid.should =~ [@billable_item2, @billable_item4] }
    end
  end

  # describe '#price' do
  #   %w[inactive beta trial suspended sponsored].each do |state|
  #     it "sets the price to 0 when in the #{state} state" do
  #       build(:addonship, state: state).price.should eq 0
  #     end
  #   end

  #   %w[subscribed].each do |state|
  #     it "gets the addon's price when in the #{state} state" do
  #       build(:addonship, state: state).price.should eq 999
  #     end
  #   end
  # end

  describe '#active?' do
    %w[suspended].each do |state|
      it "is active when in the #{state} state" do
        build(:addon_plan_billable_item, state: state).should_not be_active
      end
    end

    %w[subscribed sponsored].each do |state|
      it "isn't active when in the #{state} state" do
        build(:addon_plan_billable_item, state: state).should be_active
      end
    end
  end

end

# == Schema Information
#
# Table name: billable_items
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
#  index_billable_items_on_item_type_and_item_id              (item_type,item_id)
#  index_billable_items_on_item_type_and_item_id_and_site_id  (item_type,item_id,site_id) UNIQUE
#  index_billable_items_on_site_id                            (site_id)
#

