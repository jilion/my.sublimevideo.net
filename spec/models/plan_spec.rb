require 'spec_helper'

describe Plan do
  subject { Factory(:plan) }

  context "Factory" do
    before(:all) { @plan = Factory(:plan) }
    after(:all) { @plan.delete }
    subject { @plan }

    its(:name)          { should =~ /comet\d+/ }
    its(:cycle)         { should == "month" }
    its(:player_hits)   { should == 10_000 }
    its(:price)         { should == 1000 }
    its(:token)         { should =~ /^[a-z0-9]{12}$/ }

    it { should be_valid }
  end

  describe "Scopes" do
    specify { Plan.free_plans.all.should =~ [@beta_plan, @dev_plan, @sponsored_plan] }
    specify { Plan.paid_plans.all.should =~ [@paid_plan, @custom_plan] }
    specify { Plan.standard_plans.all.should =~ [@paid_plan] }
    specify { Plan.custom_plans.all.should =~ [@custom_plan] }
  end

  describe "Associations" do
    it { should have_many :sites }
    it { should have_many :invoice_items }
  end

  describe "Validations" do
    [:name, :cycle, :player_hits, :price].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:player_hits) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:cycle) }

    describe "uniqueness of name scoped by cycle" do
      before(:each) do
        Factory(:plan, :name => "foo", :cycle => "month")
      end

      it { Factory.build(:plan, :name => "foo", :cycle => "month").should_not be_valid }
      it { Factory.build(:plan, :name => "foo", :cycle => "year").should be_valid }
    end

    it { should validate_numericality_of(:player_hits) }
    it { should validate_numericality_of(:price) }

    it { should allow_value("month").for(:cycle) }
    it { should allow_value("year").for(:cycle) }
    it { should allow_value("none").for(:cycle) }
    it { should_not allow_value("foo").for(:cycle) }
  end

  describe "Class Methods" do
    describe ".create_custom" do
      it "should create new custom plan" do
        expect { @plan = Plan.create_custom(:cycle => "month", :player_hits => 10**7, :price => 999900) }.to change(Plan.custom_plans, :count)
        @plan.name.should == "custom#{Plan.custom_plans.count}"
      end
    end
  end

  describe "Instance Methods" do
    describe "#next_plan" do
      it "should return the next plan with a bigger price" do
        plan2 = Factory(:plan, :price => subject.price + 100)
        plan3 = Factory(:plan, :price => subject.price + 2000)
        @paid_plan.next_plan.should == plan2
      end

      it "should be_nil if none bigger plan exist" do
        plan2 = Factory(:plan, :price => 10**9)
        plan2.next_plan.should be_nil
      end
    end

    describe "#month_price" do
      context "with month plan" do
        subject { Factory.build(:plan, :cycle => "month", :price => 1000) }

        its(:month_price) { should == 1000 }
      end

      context "with year plan" do
        subject { Factory.build(:plan, :cycle => "year", :price => 10000) }

        its(:month_price) { should == 10000 / 12 }
      end
    end

    describe "#dev_plan?" do
      it { Factory.build(:plan, :name => "dev").should be_dev_plan }
      it { Factory.build(:plan, :name => "pro").should_not be_dev_plan }
    end

    describe "#sponsored_plan?" do
      it { Factory.build(:plan, :name => "dev").should_not be_sponsored_plan }
      it { Factory.build(:plan, :name => "pro").should_not be_sponsored_plan }
      it { Factory.build(:plan, :name => "sponsored").should be_sponsored_plan }
    end

    describe "#beta_plan?" do
      it { Factory.build(:plan, :name => "beta").should be_beta_plan }
      it { Factory.build(:plan, :name => "dev").should_not be_beta_plan }
    end

    describe "#standard_plan?" do
      it { Factory.build(:plan, :name => "dev").should_not be_standard_plan }
      it { Factory.build(:plan, :name => "beta").should_not be_standard_plan }
      it { Factory.build(:plan, :name => "sponsored").should_not be_standard_plan }

      Plan::STANDARD_NAMES.each do |name|
        it { Factory.build(:plan, :name => name).should be_standard_plan }
      end
    end

    describe "#custom_plan?" do
      it { Factory.build(:plan, :name => "beta").should_not be_custom_plan }
      it { Factory.build(:plan, :name => "dev").should_not be_custom_plan }
      it { Factory.build(:plan, :name => "sponsored").should_not be_custom_plan }
      it { Factory.build(:plan, :name => "comet").should_not be_custom_plan }
      it { Factory.build(:plan, :name => "custom").should be_custom_plan }
      it { Factory.build(:plan, :name => "custom1").should be_custom_plan }
      it { Factory.build(:plan, :name => "custom2").should be_custom_plan }
    end

    describe "#free_plan?" do
      it { Factory.build(:plan, :name => "beta").should be_free_plan }
      it { Factory.build(:plan, :name => "dev").should be_free_plan }
      it { Factory.build(:plan, :name => "sponsored").should be_free_plan }
      it { Factory.build(:plan, :name => "comet").should_not be_free_plan }
      it { Factory.build(:plan, :name => "custom").should_not be_free_plan }
      it { Factory.build(:plan, :name => "custom1").should_not be_free_plan }
      it { Factory.build(:plan, :name => "custom2").should_not be_free_plan }
    end

    describe "#paid_plan?" do
      it { Factory.build(:plan, :name => "beta").should_not be_paid_plan }
      it { Factory.build(:plan, :name => "dev").should_not be_paid_plan }
      it { Factory.build(:plan, :name => "sponsored").should_not be_paid_plan }
      it { Factory.build(:plan, :name => "comet").should be_paid_plan }
      it { Factory.build(:plan, :name => "custom").should be_paid_plan }
      it { Factory.build(:plan, :name => "custom1").should be_paid_plan }
      it { Factory.build(:plan, :name => "custom2").should be_paid_plan }
    end

    describe "#monthly?, #yearly? and #nonely?" do
      it { Factory.build(:plan, cycle: "month").should be_monthly }
      it { Factory.build(:plan, cycle: "year").should be_yearly }
      it { Factory.build(:plan, cycle: "none").should be_nonely }
    end

    describe "#upgrade?" do
      before(:all) do
        @paid_plan         = Factory.build(:plan, cycle: "month", price: 1000)
        @paid_plan2        = Factory.build(:plan, cycle: "month", price: 5000)
        @paid_plan_yearly  = Factory.build(:plan, cycle: "year",  price: 10000)
        @paid_plan_yearly2 = Factory.build(:plan, cycle: "year",  price: 50000)
      end

      it { @dev_plan.upgrade?(@dev_plan).should be_nil }
      it { @dev_plan.upgrade?(@paid_plan).should be_true }
      it { @dev_plan.upgrade?(@paid_plan2).should be_true }
      it { @dev_plan.upgrade?(@paid_plan_yearly).should be_true }
      it { @dev_plan.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan.upgrade?(@dev_plan).should be_false }
      it { @paid_plan.upgrade?(@paid_plan).should be_nil }
      it { @paid_plan.upgrade?(@paid_plan2).should be_true }
      it { @paid_plan.upgrade?(@paid_plan_yearly).should be_true }
      it { @paid_plan.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan2.upgrade?(@dev_plan).should be_false }
      it { @paid_plan2.upgrade?(@paid_plan).should be_false }
      it { @paid_plan2.upgrade?(@paid_plan2).should be_nil }
      it { @paid_plan2.upgrade?(@paid_plan_yearly).should be_false }
      it { @paid_plan2.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan_yearly.upgrade?(@dev_plan).should be_false }
      it { @paid_plan_yearly.upgrade?(@paid_plan).should be_false }
      it { @paid_plan_yearly.upgrade?(@paid_plan2).should be_false }
      it { @paid_plan_yearly.upgrade?(@paid_plan_yearly).should be_nil }
      it { @paid_plan_yearly.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan_yearly2.upgrade?(@dev_plan).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan2).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan_yearly).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan_yearly2).should be_nil }
    end

    describe "#title" do
      specify { @dev_plan.title.should == "Free LaunchPad" }
      specify { @dev_plan.title(always_with_cycle: true).should == "Free LaunchPad" }
      specify { @sponsored_plan.title.should == "Sponsored" }
      specify { @sponsored_plan.title(always_with_cycle: true).should == "Sponsored" }
      specify { Factory.build(:plan, cycle: "month", name: "comet").title.should == "Comet" }
      specify { Factory.build(:plan, cycle: "year", name: "comet").title.should == "Comet (yearly)" }
      specify { Factory.build(:plan, cycle: "month", name: "comet").title(always_with_cycle: true).should == "Comet (monthly)" }
      specify { Factory.build(:plan, cycle: "year", name: "comet").title(always_with_cycle: true).should == "Comet (yearly)" }
    end

    describe "#daily_player_hits" do
      before(:all) do
        @plan1 = Factory.build(:plan, cycle: "month", player_hits: 1000)
        @plan2 = Factory.build(:plan, cycle: "year", player_hits: 2000)
        @plan3 = Factory.build(:plan, cycle: "none", player_hits: 3000)
      end

      it { @plan1.daily_player_hits.should == 33 }
      it { @plan2.daily_player_hits.should == 66 }
      it { @plan3.daily_player_hits.should == 100 }
    end

    describe "#support" do
      it { Factory.build(:plan, :name => "beta").support.should == "standard" }
      it { Factory.build(:plan, :name => "dev").support.should == "standard" }
      it { Factory.build(:plan, :name => "sponsored").support.should == "priority" }
      it { Factory.build(:plan, :name => "comet").support.should == "standard" }
      it { Factory.build(:plan, :name => "planet").support.should == "standard" }
      it { Factory.build(:plan, :name => "star").support.should == "priority" }
      it { Factory.build(:plan, :name => "galaxy").support.should == "priority" }
      it { Factory.build(:plan, :name => "custom").support.should == "priority" }
      it { Factory.build(:plan, :name => "custom1").support.should == "priority" }
    end
    
    describe "#price" do
      before(:all) do
        @beta_user = Factory(:user, enthusiast_id: 1234)
        @non_beta_user = Factory(:user, enthusiast_id: nil)
        @paid_plan2 = Factory(:plan, cycle: "month", player_hits: 50_000, price: 1990) # $19.90
        
        Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.hour) do # before beta end
          @beta_user_dev_site1 = Factory(:site, user: @beta_user, plan_id: @dev_plan.id)
          @beta_user_beta_site1 = Factory(:site, user: @beta_user, plan_id: @beta_plan.id)
          @beta_user_paid_site1 = Factory(:site, user: @beta_user, plan_id: @paid_plan.id)
          @beta_user_paid_site_with_pending_plan_id1 = Factory(:site, user: @beta_user, plan_id: @paid_plan.id)
          @beta_user_paid_site_with_pending_plan_id1.pending_plan_id = @paid_plan2.id
        end
        
        Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.hour) do # after beta end
          @beta_user_dev_site2 = Factory(:site, user: @beta_user, plan_id: @dev_plan.id)
          @beta_user_beta_site2 = Factory(:site, user: @beta_user, plan_id: @beta_plan.id)
          @beta_user_paid_site2 = Factory(:site, user: @beta_user, plan_id: @paid_plan.id)
        end
        
        Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.hour) do # before beta end
          @non_beta_user_dev_site1 = Factory(:site, user: @non_beta_user, plan_id: @dev_plan.id)
          @non_beta_user_paid_site1 = Factory(:site, user: @non_beta_user, plan_id: @paid_plan.id)
        end
        
        Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.hour) do # after beta end
          @non_beta_user_dev_site2 = Factory(:site, user: @non_beta_user, plan_id: @dev_plan.id)
          @non_beta_user_paid_site2 = Factory(:site, user: @non_beta_user, plan_id: @paid_plan.id)
        end
        
        @beta_user_dev_site1.first_paid_plan_started_at.should be_nil
        @beta_user_beta_site1.first_paid_plan_started_at.should be_nil
        @beta_user_paid_site1.first_paid_plan_started_at.should == PublicLaunch.beta_transition_ended_on.yesterday
        @beta_user_paid_site_with_pending_plan_id1.first_paid_plan_started_at.should == PublicLaunch.beta_transition_ended_on.yesterday
        @beta_user_paid_site_with_pending_plan_id1.pending_plan_id.should == @paid_plan2.id
        @beta_user_dev_site2.first_paid_plan_started_at.should be_nil
        @beta_user_beta_site2.first_paid_plan_started_at.should be_nil
        @beta_user_paid_site2.first_paid_plan_started_at.should == PublicLaunch.beta_transition_ended_on
        
        @non_beta_user_dev_site1.first_paid_plan_started_at.should be_nil
        @non_beta_user_paid_site1.first_paid_plan_started_at.should == PublicLaunch.beta_transition_ended_on.yesterday
        @non_beta_user_dev_site2.first_paid_plan_started_at.should be_nil
        @non_beta_user_paid_site2.first_paid_plan_started_at.should == PublicLaunch.beta_transition_ended_on
      end
      
      it { @paid_plan2.price(@beta_user_dev_site1).should == 1590 }
      it { @paid_plan2.price(@beta_user_beta_site1).should == 1590 }
      it { @paid_plan2.price(@beta_user_paid_site1).should == 1590 }
      
      # should not return the discounted price anymore for plans not bought before the end of beta
      it { Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.day) { @paid_plan2.price(@beta_user_dev_site1).should == 1990 } }
      it { Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.day) { @paid_plan2.price(@beta_user_beta_site1).should == 1990 } }
      # should still return the discounted price for plans first bought before the end of beta
      it { Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.day) { @paid_plan2.price(@beta_user_paid_site1).should == 1590 } }
      # should still return the discounted price for plans first bought before the end of beta
      it { Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.day) { @paid_plan2.price(@beta_user_paid_site_with_pending_plan_id1).should == 1990 } }
      
      it { @paid_plan2.price(@beta_user_dev_site2).should == 1590 }
      it { @paid_plan2.price(@beta_user_beta_site2).should == 1590 }
      it { @paid_plan2.price(@beta_user_paid_site2).should == 1990 }
      
      it { @paid_plan2.price(@non_beta_user_dev_site1).should == 1990 }
      it { @paid_plan2.price(@non_beta_user_paid_site1).should == 1990 }
      
      it { @paid_plan2.price(@non_beta_user_dev_site2).should == 1990 }
      it { @paid_plan2.price(@non_beta_user_paid_site2).should == 1990 }
    end

  end

end



# == Schema Information
#
# Table name: plans
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  token       :string(255)
#  cycle       :string(255)
#  player_hits :integer
#  price       :integer
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#


# == Schema Information
#
# Table name: plans
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  token       :string(255)
#  cycle       :string(255)
#  player_hits :integer
#  price       :integer
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#

