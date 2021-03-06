require 'spec_helper'

describe Deal do
  context "Factory" do
    subject { create(:deal) }

    its(:token)              { should be_present }
    its(:name)               { should be_present }
    its(:description)        { should be_nil }
    its(:kind)               { should be_present }
    its(:value)              { should be_nil }
    its(:availability_scope) { should be_present }
    its(:started_at)         { should be_present }
    its(:ended_at)           { should be_present }

    it { should be_valid }
  end # Factory

  describe "Associations" do
    subject { create(:deal) }

    it { should have_many :deal_activations }
    it { should have_many :invoice_items }
  end # Associations

  describe "Validations" do
    subject { create(:deal) }

    it { should validate_presence_of(:token) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:kind) }
    it { should validate_presence_of(:availability_scope) }
    it { should validate_presence_of(:started_at) }
    it { should validate_presence_of(:ended_at) }
  end # Validations

  describe "Callbacks" do
    describe "ensure availability_scope is valid" do
      it "adds an error if availability_scope isn't valid" do
        deal = build(:deal, availability_scope: 'foo')
        deal.should_not be_valid
        deal.should have(1).error
      end

      it "doesn't add an error if availability_scope is valid" do
        deal = build(:deal, availability_scope: 'vip')
        deal.should be_valid
      end
    end
  end

  describe "Scopes" do
    describe ".active" do
      before { @deal = create(:deal, started_at: 2.days.ago, ended_at: 2.days.from_now) }

      context "now is before the deal has started" do
        before { Timecop.travel(3.days.ago) }
        after { Timecop.return }

        it "returns an empty array" do
          described_class.active.should be_empty
        end
      end

      context "now is after the deal has started" do
        before { Timecop.travel(3.days.from_now) }
        after { Timecop.return }

        it "returns an empty array" do
          described_class.active.should be_empty
        end
      end

      context "now is between the deal start and end date" do
        it "returns the deal" do
          described_class.active.should eq [@deal]
        end
      end
    end
  end

  describe "Instance methods" do
    describe "#active?" do
      before { @deal = create(:deal, started_at: 2.days.ago, ended_at: 2.days.from_now) }
      subject { @deal }

      context "now is before the deal has started" do
        before { Timecop.travel(3.days.ago) }
        after { Timecop.return }

        it { should_not be_active }
      end

      context "now is after the deal has started" do
        before { Timecop.travel(3.days.from_now) }
        after { Timecop.return }

        it { should_not be_active }
      end

      context "now is between the deal start and end date" do
        it { should be_active }
      end
    end

    describe "#available_to?" do
      let(:user_dont_use_for_clients) { create(:user, vip: false) }
      let(:user_use_for_clients)      { create(:user, vip: true) }
      let(:deal)                      { create(:deal, availability_scope: 'vip') }

      it "return false if user is nil" do
        deal.available_to?(nil).should be_false
      end

      it "return false if user isn't included in the availability_scope" do
        deal.available_to?(user_dont_use_for_clients).should be_false
      end

      it "return true if user is included in the availability_scope" do
        deal.available_to?(user_use_for_clients).should be_true
      end
    end
  end

end

# == Schema Information
#
# Table name: deals
#
#  availability_scope :string(255)
#  created_at         :datetime
#  description        :text
#  ended_at           :datetime
#  id                 :integer          not null, primary key
#  kind               :string(255)
#  name               :string(255)
#  started_at         :datetime
#  token              :string(255)
#  updated_at         :datetime
#  value              :float
#
# Indexes
#
#  index_deals_on_token  (token) UNIQUE
#

