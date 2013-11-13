require 'spec_helper'

describe DealActivation do
  context "Factory" do
    subject { create(:deal_activation) }

    describe '#deal_id' do
      subject { super().deal_id }
      it      { should be_present }
    end

    describe '#user_id' do
      subject { super().user_id }
      it      { should be_present }
    end

    describe '#activated_at' do
      subject { super().activated_at }
      it { should be_present }
    end

    it { should be_valid }
  end # Factory

  describe "Associations" do
    subject { create(:deal_activation) }

    it { should belong_to :deal }
    it { should belong_to :user }
  end # Associations

  describe "Validations" do
    subject { create(:deal_activation) }

    it { should validate_presence_of(:deal_id) }
    it { should validate_presence_of(:user_id) }
  end # Validations

  describe "Scopes" do
    describe ".active" do
      before do
        @deal_activation = create(:deal_activation, deal: create(:deal, started_at: 2.days.ago, ended_at: 2.days.from_now))
        Timecop.travel(2.days.ago) { create(:deal_activation, deal: create(:deal, started_at: 1.day.ago, ended_at: 1.day.from_now)) }
      end

      it { expect(described_class.active).to eq [@deal_activation] }
    end
  end

  describe "Callbacks" do
    describe "ensures the deal is currently active" do
      let(:deal) { create(:deal) }

      context "deal is not active" do
        before { expect(deal).to receive(:active?) { false } }

        it "doesn't create a DealActivation record" do
          deal_activation = build(:deal_activation, deal: deal)
          expect(deal_activation).not_to be_valid
          expect(deal_activation.errors.size).to eq(1)
        end
      end

      context "deal is active" do
        before { expect(deal).to receive(:active?) { true } }

        it "creates a DealActivation record" do
          expect { create(:deal_activation, deal: deal) }.to change(DealActivation, :count).by(1)
        end
      end
    end

    describe "ensures the user has the right to activate the deal" do
      let(:deal) { create(:deal, availability_scope: 'vip') }

      context "user isn't included in the available_to scope of the deal record" do
        before { expect(deal).to receive(:available_to?) { false } }

        it "doesn't create a DealActivation record" do
          deal_activation = build(:deal_activation, deal: deal)
          expect(deal_activation).not_to be_valid
          expect(deal_activation.errors.size).to eq(1)
        end
      end

      context "user is included in the available_to scope of the deal record" do
        before { expect(deal).to receive(:available_to?) { true } }

        it "creates a DealActivation record" do
          expect { create(:deal_activation, deal: deal) }.to change(DealActivation, :count).by(1)
        end
      end
    end

    it "set activated_at before validations if not present" do
      deal_activation = build(:deal_activation)
      expect(deal_activation.activated_at).to be_nil

      deal_activation.valid?
      expect(deal_activation.activated_at).to be_present
    end
  end
end

# == Schema Information
#
# Table name: deal_activations
#
#  activated_at :datetime
#  created_at   :datetime
#  deal_id      :integer
#  id           :integer          not null, primary key
#  updated_at   :datetime
#  user_id      :integer
#
# Indexes
#
#  index_deal_activations_on_deal_id_and_user_id  (deal_id,user_id) UNIQUE
#

