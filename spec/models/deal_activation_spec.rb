require 'spec_helper'

describe DealActivation do
  context "Factory" do
    subject { create(:deal_activation) }

    its(:deal_id)      { should be_present }
    its(:user_id)      { should be_present }
    its(:activated_at) { should be_present }

    it { should be_valid }
  end # Factory

  describe "Associations" do
    subject { create(:deal_activation) }

    it { should belong_to :deal }
    it { should belong_to :user }
  end # Associations

  describe "Validations" do
    subject { create(:deal_activation) }

    [:deal_id, :user_id].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:deal_id) }
    it { should validate_presence_of(:user_id) }
  end # Validations

  describe "Scopes" do
    describe ".active" do
      before do
        @deal_activation = create(:deal_activation, deal: create(:deal, started_at: 2.days.ago, ended_at: 2.days.from_now))
        Timecop.travel(2.days.ago) { create(:deal_activation, deal: create(:deal, started_at: 1.day.ago, ended_at: 1.day.from_now)) }
      end

      it { described_class.active.should eq [@deal_activation] }
    end
  end

  describe "Callbacks" do
    describe "ensures the deal is currently active" do
      let(:deal) { create(:deal) }

      context "deal is not active" do
        before { deal.should_receive(:active?) { false } }

        it "doesn't create a DealActivation record" do
          deal_activation = build(:deal_activation, deal: deal)
          deal_activation.should_not be_valid
          deal_activation.should have(1).error
        end
      end

      context "deal is active" do
        before { deal.should_receive(:active?) { true } }

        it "creates a DealActivation record" do
          expect { create(:deal_activation, deal: deal) }.to change(DealActivation, :count).by(1)
        end
      end
    end

    describe "ensures the user has the right to activate the deal" do
      let(:deal) { create(:deal, availability_scope: 'use_clients') }

      context "user isn't included in the available_to scope of the deal record" do
        before { deal.should_receive(:available_to?) { false } }

        it "doesn't create a DealActivation record" do
          deal_activation = build(:deal_activation, deal: deal)
          deal_activation.should_not be_valid
          deal_activation.should have(1).error
        end
      end

      context "user is included in the available_to scope of the deal record" do
        before { deal.should_receive(:available_to?) { true } }

        it "creates a DealActivation record" do
          expect { create(:deal_activation, deal: deal) }.to change(DealActivation, :count).by(1)
        end
      end
    end

    it "set activated_at before validations if not present" do
      deal_activation = build(:deal_activation)
      deal_activation.activated_at.should be_nil

      deal_activation.valid?
      deal_activation.activated_at.should be_present
    end
  end
end

# == Schema Information
#
# Table name: deal_activations
#
#  id           :integer         not null, primary key
#  deal_id      :integer
#  user_id      :integer
#  activated_at :datetime
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#
# Indexes
#
#  index_deal_activations_on_deal_id_and_user_id  (deal_id,user_id) UNIQUE
#

