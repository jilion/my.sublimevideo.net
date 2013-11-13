require 'spec_helper'

describe Plan do
  let(:custom_plan) { create(:plan, price: 999, name: 'custom - 1') }

  context "Factory" do
    subject { create(:plan) }

    describe '#name' do
      subject { super().name }
      it                 { should =~ /plus\d+/ }
    end

    describe '#cycle' do
      subject { super().cycle }
      it                { should eq "month" }
    end

    describe '#video_views' do
      subject { super().video_views }
      it          { should eq 10_000 }
    end

    describe '#stats_retention_days' do
      subject { super().stats_retention_days }
      it { should eq 365 }
    end

    describe '#price' do
      subject { super().price }
      it                { should eq 1000 }
    end

    it { should be_valid }
  end

  describe "Instance Methods" do
    describe "#title" do
      specify { expect(custom_plan.title).to eq "Custom Plan" }
      specify { expect(build(:plan, cycle: "month", name: "comet").title).to eq "Comet Plan" }
      specify { expect(build(:plan, cycle: "year", name: "comet").title).to eq "Comet Plan (yearly)" }
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
