require 'spec_helper'

describe Plan do
  subject { FactoryGirl.create(:plan) }

  context "Factory" do
    before(:all) { @plan = FactoryGirl.create(:plan) }
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
    specify { Plan.unpaid_plans.all.should =~ [@beta_plan, @free_plan, @sponsored_plan] }
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
        FactoryGirl.create(:plan, :name => "foo", :cycle => "month")
      end

      it { FactoryGirl.build(:plan, :name => "foo", :cycle => "month").should_not be_valid }
      it { FactoryGirl.build(:plan, :name => "foo", :cycle => "year").should be_valid }
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
        Plan.delete_all
        expect { @plan = Plan.create_custom(:cycle => "month", :player_hits => 10**7, :price => 999900) }.to change(Plan.custom_plans, :count).by(1)
        @plan.name.should == "custom#{Plan.custom_plans.count}"
      end
    end
  end

  describe "Instance Methods" do
    describe "#next_plan" do
      it "should return the next plan with a bigger price" do
        plan2 = FactoryGirl.create(:plan, :price => subject.price + 100)
        plan3 = FactoryGirl.create(:plan, :price => subject.price + 2000)
        @paid_plan.next_plan.should == plan2
      end

      it "should be_nil if none bigger plan exist" do
        plan2 = FactoryGirl.create(:plan, :price => 10**9)
        plan2.next_plan.should be_nil
      end
    end

    describe "#month_price" do
      context "with month plan" do
        subject { FactoryGirl.build(:plan, :cycle => "month", :price => 1000) }

        its(:month_price) { should == 1000 }
      end

      context "with year plan" do
        subject { FactoryGirl.build(:plan, :cycle => "year", :price => 10000) }

        its(:month_price) { should == 10000 / 12 }
      end
    end

    describe "#free_plan?" do
      it { FactoryGirl.build(:plan, :name => "free").should be_free_plan }
      it { FactoryGirl.build(:plan, :name => "pro").should_not be_free_plan }
    end

    describe "#sponsored_plan?" do
      it { FactoryGirl.build(:plan, :name => "free").should_not be_sponsored_plan }
      it { FactoryGirl.build(:plan, :name => "pro").should_not be_sponsored_plan }
      it { FactoryGirl.build(:plan, :name => "sponsored").should be_sponsored_plan }
    end

    describe "#beta_plan?" do
      it { FactoryGirl.build(:plan, :name => "beta").should be_beta_plan }
      it { FactoryGirl.build(:plan, :name => "free").should_not be_beta_plan }
    end

    describe "#standard_plan?" do
      it { FactoryGirl.build(:plan, :name => "free").should_not be_standard_plan }
      it { FactoryGirl.build(:plan, :name => "beta").should_not be_standard_plan }
      it { FactoryGirl.build(:plan, :name => "sponsored").should_not be_standard_plan }

      Plan::STANDARD_NAMES.each do |name|
        it { FactoryGirl.build(:plan, :name => name).should be_standard_plan }
      end
    end

    describe "#custom_plan?" do
      it { FactoryGirl.build(:plan, :name => "beta").should_not be_custom_plan }
      it { FactoryGirl.build(:plan, :name => "free").should_not be_custom_plan }
      it { FactoryGirl.build(:plan, :name => "sponsored").should_not be_custom_plan }
      it { FactoryGirl.build(:plan, :name => "comet").should_not be_custom_plan }
      it { FactoryGirl.build(:plan, :name => "custom").should be_custom_plan }
      it { FactoryGirl.build(:plan, :name => "custom1").should be_custom_plan }
      it { FactoryGirl.build(:plan, :name => "custom2").should be_custom_plan }
    end

    describe "#unpaid_plan?" do
      it { FactoryGirl.build(:plan, :name => "beta").should be_unpaid_plan }
      it { FactoryGirl.build(:plan, :name => "free").should be_unpaid_plan }
      it { FactoryGirl.build(:plan, :name => "sponsored").should be_unpaid_plan }
      it { FactoryGirl.build(:plan, :name => "comet").should_not be_unpaid_plan }
      it { FactoryGirl.build(:plan, :name => "custom").should_not be_unpaid_plan }
      it { FactoryGirl.build(:plan, :name => "custom1").should_not be_unpaid_plan }
      it { FactoryGirl.build(:plan, :name => "custom2").should_not be_unpaid_plan }
    end

    describe "#paid_plan?" do
      it { FactoryGirl.build(:plan, :name => "beta").should_not be_paid_plan }
      it { FactoryGirl.build(:plan, :name => "free").should_not be_paid_plan }
      it { FactoryGirl.build(:plan, :name => "sponsored").should_not be_paid_plan }
      it { FactoryGirl.build(:plan, :name => "comet").should be_paid_plan }
      it { FactoryGirl.build(:plan, :name => "custom").should be_paid_plan }
      it { FactoryGirl.build(:plan, :name => "custom1").should be_paid_plan }
      it { FactoryGirl.build(:plan, :name => "custom2").should be_paid_plan }
    end

    describe "#monthly?, #yearly? and #nonely?" do
      it { FactoryGirl.build(:plan, cycle: "month").should be_monthly }
      it { FactoryGirl.build(:plan, cycle: "year").should be_yearly }
      it { FactoryGirl.build(:plan, cycle: "none").should be_nonely }
    end

    describe "#upgrade?" do
      before(:all) do
        @paid_plan         = FactoryGirl.build(:plan, cycle: "month", price: 1000)
        @paid_plan2        = FactoryGirl.build(:plan, cycle: "month", price: 5000)
        @paid_plan_yearly  = FactoryGirl.build(:plan, cycle: "year",  price: 10000)
        @paid_plan_yearly2 = FactoryGirl.build(:plan, cycle: "year",  price: 50000)
      end

      it { @beta_plan.upgrade?(@free_plan).should be_true }
      it { @beta_plan.upgrade?(@sponsored_plan).should be_true }
      it { @beta_plan.upgrade?(@custom_plan).should be_true }
      it { @beta_plan.upgrade?(@paid_plan).should be_true }
      it { @beta_plan.upgrade?(@paid_plan2).should be_true }
      it { @beta_plan.upgrade?(@paid_plan_yearly).should be_true }
      it { @beta_plan.upgrade?(@paid_plan_yearly2).should be_true }

      it { @free_plan.upgrade?(@free_plan).should be_nil }
      it { @free_plan.upgrade?(@paid_plan).should be_true }
      it { @free_plan.upgrade?(@paid_plan2).should be_true }
      it { @free_plan.upgrade?(@paid_plan_yearly).should be_true }
      it { @free_plan.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan.upgrade?(@free_plan).should be_false }
      it { @paid_plan.upgrade?(@paid_plan).should be_nil }
      it { @paid_plan.upgrade?(@paid_plan2).should be_true }
      it { @paid_plan.upgrade?(@paid_plan_yearly).should be_true }
      it { @paid_plan.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan2.upgrade?(@free_plan).should be_false }
      it { @paid_plan2.upgrade?(@paid_plan).should be_false }
      it { @paid_plan2.upgrade?(@paid_plan2).should be_nil }
      it { @paid_plan2.upgrade?(@paid_plan_yearly).should be_false }
      it { @paid_plan2.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan_yearly.upgrade?(@free_plan).should be_false }
      it { @paid_plan_yearly.upgrade?(@paid_plan).should be_false }
      it { @paid_plan_yearly.upgrade?(@paid_plan2).should be_false }
      it { @paid_plan_yearly.upgrade?(@paid_plan_yearly).should be_nil }
      it { @paid_plan_yearly.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan_yearly2.upgrade?(@free_plan).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan2).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan_yearly).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan_yearly2).should be_nil }
    end

    describe "#title" do
      specify { @free_plan.title.should == "Free LaunchPad" }
      specify { @free_plan.title(always_with_cycle: true).should == "Free LaunchPad" }
      specify { @sponsored_plan.title.should == "Sponsored" }
      specify { @sponsored_plan.title(always_with_cycle: true).should == "Sponsored" }
      specify { @custom_plan.title.should == "Custom" }
      specify { @custom_plan.title(always_with_cycle: true).should == "Custom (monthly)" }
      specify { FactoryGirl.build(:plan, cycle: "month", name: "comet").title.should == "Comet" }
      specify { FactoryGirl.build(:plan, cycle: "year", name: "comet").title.should == "Comet (yearly)" }
      specify { FactoryGirl.build(:plan, cycle: "month", name: "comet").title(always_with_cycle: true).should == "Comet (monthly)" }
      specify { FactoryGirl.build(:plan, cycle: "year", name: "comet").title(always_with_cycle: true).should == "Comet (yearly)" }
    end

    describe "#daily_player_hits" do
      before(:all) do
        @plan1 = FactoryGirl.build(:plan, cycle: "month", player_hits: 1000)
        @plan2 = FactoryGirl.build(:plan, cycle: "year", player_hits: 2000)
        @plan3 = FactoryGirl.build(:plan, cycle: "none", player_hits: 3000)
      end

      it { @plan1.daily_player_hits.should == 33 }
      it { @plan2.daily_player_hits.should == 66 }
      it { @plan3.daily_player_hits.should == 100 }
    end

    describe "#support" do
      it { FactoryGirl.build(:plan, :name => "beta").support.should == "standard" }
      it { FactoryGirl.build(:plan, :name => "free").support.should == "launchpad" }
      it { FactoryGirl.build(:plan, :name => "sponsored").support.should == "priority" }
      it { FactoryGirl.build(:plan, :name => "comet").support.should == "standard" }
      it { FactoryGirl.build(:plan, :name => "planet").support.should == "standard" }
      it { FactoryGirl.build(:plan, :name => "star").support.should == "priority" }
      it { FactoryGirl.build(:plan, :name => "galaxy").support.should == "priority" }
      it { FactoryGirl.build(:plan, :name => "custom").support.should == "priority" }
      it { FactoryGirl.build(:plan, :name => "custom1").support.should == "priority" }
    end

    describe "#price(site)" do
      before(:all) do
        @beta_user = FactoryGirl.create(:user, invitation_token: nil, created_at: Time.utc(2010,10,10))
        @non_beta_user = FactoryGirl.create(:user, invitation_token: "1234asdv")
        @paid_plan2 = FactoryGirl.create(:plan, cycle: "month", player_hits: 50_000, price: 1990) # $19.90

        Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.day) do # before beta end
          @beta_user_free_site1 = FactoryGirl.create(:site, user: @beta_user, plan_id: @free_plan.id)
          @beta_user_beta_site1 = FactoryGirl.create(:site, user: @beta_user, plan_id: @beta_plan.id)
          @beta_user_paid_site1 = FactoryGirl.create(:site, user: @beta_user, plan_id: @paid_plan.id)
          @beta_user_paid_site11 = FactoryGirl.create(:site_with_invoice, user: @beta_user, plan_id: @paid_plan.id)
          @beta_user_paid_site11.plan_id = FactoryGirl.create(:plan).id
          VCR.use_cassette('ogone/visa_payment_generic') { @beta_user_paid_site11.save_without_password_validation }
          @beta_user_paid_site11.invoices.count.should == 2
        end

        Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.day) do # after beta end
          @beta_user_free_site2 = FactoryGirl.create(:site, user: @beta_user, plan_id: @free_plan.id)
          @beta_user_beta_site2 = FactoryGirl.create(:site, user: @beta_user, plan_id: @beta_plan.id)
          @beta_user_paid_site2 = FactoryGirl.create(:site, user: @beta_user, plan_id: @paid_plan.id)
        end

        Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.day) do # before beta end
          @non_beta_user_free_site1 = FactoryGirl.create(:site, user: @non_beta_user, plan_id: @free_plan.id)
          @non_beta_user_paid_site1 = FactoryGirl.create(:site, user: @non_beta_user, plan_id: @paid_plan.id)
        end

        Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.day) do # after beta end
          @non_beta_user_free_site2 = FactoryGirl.create(:site, user: @non_beta_user, plan_id: @free_plan.id)
          @non_beta_user_paid_site2 = FactoryGirl.create(:site, user: @non_beta_user, plan_id: @paid_plan.id)
        end

        @beta_user_free_site1.first_paid_plan_started_at.should be_nil
        @beta_user_beta_site1.first_paid_plan_started_at.should be_nil
        @beta_user_paid_site1.first_paid_plan_started_at.should == PublicLaunch.beta_transition_ended_on.yesterday.midnight
        @beta_user_free_site2.first_paid_plan_started_at.should be_nil
        @beta_user_beta_site2.first_paid_plan_started_at.should be_nil
        @beta_user_paid_site2.first_paid_plan_started_at.should == PublicLaunch.beta_transition_ended_on.tomorrow.midnight

        @non_beta_user_free_site1.first_paid_plan_started_at.should be_nil
        @non_beta_user_paid_site1.first_paid_plan_started_at.should == PublicLaunch.beta_transition_ended_on.yesterday.midnight
        @non_beta_user_free_site2.first_paid_plan_started_at.should be_nil
        @non_beta_user_paid_site2.first_paid_plan_started_at.should == PublicLaunch.beta_transition_ended_on.tomorrow.midnight
      end

      # should not return the discounted price anymore for plans not bought before the end of beta
      context "before the end of the beta" do
        before(:all) { Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.day) }
        after(:all) { Timecop.return }

        it { @paid_plan2.price(@beta_user_free_site1).should == 1590 }
        it { @paid_plan2.price(@beta_user_beta_site1).should == 1590 }
        it { @paid_plan2.price(@beta_user_paid_site1).should == 1590 }
        it { @paid_plan2.price(@beta_user_paid_site11).should == 1590 }

        it { @paid_plan2.price(@beta_user_free_site2).should == 1590 }
        it { @paid_plan2.price(@beta_user_beta_site2).should == 1590 }
        it { @paid_plan2.price(@beta_user_paid_site2).should == 1590 }

        it { @paid_plan2.price(@non_beta_user_free_site1).should == 1990 }
        it { @paid_plan2.price(@non_beta_user_paid_site1).should == 1990 }

        it { @paid_plan2.price(@non_beta_user_free_site2).should == 1990 }
        it { @paid_plan2.price(@non_beta_user_paid_site2).should == 1990 }
      end

      context "after the end of the beta transition" do
        before(:all) { Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.day) }
        after(:all) { Timecop.return }

        it { @paid_plan2.price(@beta_user_free_site1).should == 1990 }
        it { @paid_plan2.price(@beta_user_beta_site1).should == 1990 }
        it "should not return the discounted price" do
          @paid_plan2.price(@beta_user_paid_site1).should == 1990
        end

        it { @paid_plan2.price(@beta_user_paid_site11).should == 1990 }
      end
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

