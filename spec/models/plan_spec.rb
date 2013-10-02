require 'spec_helper'

describe Plan do
  let(:custom_plan) { create(:plan, price: 999, name: 'custom - 1') }

  context "Factory" do
    subject { create(:plan) }

    its(:name)                 { should =~ /plus\d+/ }
    its(:cycle)                { should eq "month" }
    its(:video_views)          { should eq 10_000 }
    its(:stats_retention_days) { should eq 365 }
    its(:price)                { should eq 1000 }

    it { should be_valid }
  end

  describe "Instance Methods" do
    describe "#title" do
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
