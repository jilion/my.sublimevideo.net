# coding: utf-8
require 'spec_helper'

describe Plan do
  let(:trial_plan)     { create(:plan, price: 0, name: 'trial') }
  let(:free_plan)      { create(:plan, price: 0, name: 'free') }
  let(:paid_plan)      { create(:plan, price: 999, name: 'plus') }
  let(:custom_plan)    { create(:plan, price: 999, name: 'custom - 1') }
  let(:sponsored_plan) { create(:plan, price: 0, name: 'sponsored') }

  context "Factory" do
    subject { create(:plan) }

    its(:name)                 { should =~ /plus\d+/ }
    its(:cycle)                { should eq "month" }
    its(:video_views)          { should eq 10_000 }
    its(:stats_retention_days) { should eq 365 }
    its(:price)                { should eq 1000 }
    its(:token)                { should =~ /^[a-z0-9]{12}$/ }

    it { should be_valid }
  end

  describe "Associations" do
    subject { create(:plan) }

    it { should have_many :sites }
    it { should have_many :invoice_items }
  end

  describe "Validations" do
    subject { create(:plan) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:video_views) }
    it { should validate_presence_of(:cycle) }
    it { should validate_presence_of(:support_level) }

    it "price can't be blank" do
      build(:plan, price: nil).should have(1).error_on(:price)
    end

    describe "uniqueness of name all by cycle" do
      before { create(:plan, name: "foo", cycle: "month") }

      it { build(:plan, name: "foo", cycle: "month").should_not be_valid }
      it { build(:plan, name: "foo", cycle: "year").should be_valid }
    end

    it { should validate_numericality_of(:video_views) }

    it { should allow_value("month").for(:cycle) }
    it { should allow_value("year").for(:cycle) }
    it { should allow_value("none").for(:cycle) }
    it { should_not allow_value("foo").for(:cycle) }
  end

  describe "Instance Methods" do
    describe "#free_plan?" do
      it { build(:plan, name: "free", price: 0).should be_free_plan }
      it { build(:plan, name: "pro").should_not be_free_plan }
    end

    describe "#sponsored_plan?" do
      it { build(:plan, name: "free", price: 0).should_not be_sponsored_plan }
      it { build(:plan, name: "pro").should_not be_sponsored_plan }
      it { build(:plan, name: "sponsored", price: 0).should be_sponsored_plan }
    end

    describe "#trial_plan?" do
      it { build(:plan, name: "free", price: 0).should_not be_trial_plan }
      it { build(:plan, name: "pro").should_not be_trial_plan }
      it { build(:plan, name: "trial", price: 0).should be_trial_plan }
    end

    describe "#monthly?, #yearly? and #nonely?" do
      it { build(:plan, cycle: "month").should be_monthly }
      it { build(:plan, cycle: "year").should be_yearly }
      it { build(:plan, cycle: "none").should be_nonely }
    end

    describe "#title" do
      specify { free_plan.title.should eq "Free Plan" }
      specify { sponsored_plan.title.should eq "Sponsored Plan" }
      specify { custom_plan.title.should eq "Custom Plan" }
      specify { build(:plan, cycle: "month", name: "comet").title.should eq "Comet Plan" }
      specify { build(:plan, cycle: "year", name: "comet").title.should eq "Comet Plan (yearly)" }
    end
  end

end

# == Schema Information
#
# Table name: plans
#
#  id                   :integer         not null, primary key
#  name                 :string(255)
#  token                :string(255)
#  cycle                :string(255)
#  video_views          :integer
#  price                :integer
#  created_at           :datetime        not null
#  updated_at           :datetime        not null
#  support_level        :integer         default(0)
#  stats_retention_days :integer
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#
