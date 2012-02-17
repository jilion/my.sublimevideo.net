require 'spec_helper'

describe Deal do
  context "Factory" do
    subject { Factory(:deal) }

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
    subject { Factory(:deal) }

    it { should have_many :deal_activations }
    it { should have_many :invoice_items }
  end # Associations

  describe "Validations" do
    subject { Factory(:deal) }

    [:token, :name, :description, :kind, :value, :availability_scope, :started_at, :ended_at].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

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
        deal = Factory.build(:deal, availability_scope: 'foo')
        deal.should_not be_valid
        deal.should have(1).error
      end

      it "doesn't add an error if availability_scope is valid" do
        deal = Factory.build(:deal, availability_scope: 'use_clients')
        deal.should be_valid
      end
    end
  end

  describe "Scopes" do
    describe ".active" do
      before(:each) { @deal = Factory(:deal, started_at: 2.days.ago, ended_at: 2.days.from_now) }

      context "now is before the deal has started" do
        before(:each) { Timecop.travel(3.days.ago) }
        after(:each) { Timecop.return }

        it "returns an empty array" do
          described_class.active.should be_empty
        end
      end

      context "now is after the deal has started" do
        before(:each) { Timecop.travel(3.days.from_now) }
        after(:each) { Timecop.return }

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
      before(:each) { @deal = Factory(:deal, started_at: 2.days.ago, ended_at: 2.days.from_now) }
      subject { @deal }

      context "now is before the deal has started" do
        before(:each) { Timecop.travel(3.days.ago) }
        after(:each) { Timecop.return }

        it { should_not be_active }
      end

      context "now is after the deal has started" do
        before(:each) { Timecop.travel(3.days.from_now) }
        after(:each) { Timecop.return }

        it { should_not be_active }
      end

      context "now is between the deal start and end date" do
        it { should be_active }
      end
    end

    describe "#available_to?" do
      let(:user_dont_use_for_clients) { Factory(:user, use_clients: false) }
      let(:user_use_for_clients)      { Factory(:user, use_clients: true) }
      let(:deal)                      { Factory(:deal, availability_scope: 'use_clients') }

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
#  id                 :integer         not null, primary key
#  token              :string(255)
#  name               :string(255)
#  description        :text
#  kind               :string(255)
#  value              :float
#  availability_scope :string(255)
#  started_at         :datetime
#  ended_at           :datetime
#  created_at         :datetime
#  updated_at         :datetime
#
# Indexes
#
#  index_deals_on_token  (token) UNIQUE
#

