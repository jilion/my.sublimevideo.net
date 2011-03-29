# coding: utf-8
require 'spec_helper'

describe Site do

  # describe "Test site with and without invoice" do
  #
  #   context "WITH INVOICE" do
  #     subject { Factory(:site_with_invoice) }
  #     it "should be slow" do
  #       start_time = Time.now
  #       subject.plan_id.should be_present
  #       subject.invoices.count.should == 1
  #       puts "WITH INVOICE: Done in #{Time.now - start_time} seconds!"
  #     end
  #   end
  #
  #   context "WITHOUT INVOICE" do
  #     subject { Factory(:site) }
  #     it "should be quick" do
  #       start_time = Time.now
  #       subject.plan_id.should be_present
  #       subject.invoices.count.should == 0
  #       puts "WITHOUT INVOICE: Done in #{Time.now - start_time} seconds!"
  #     end
  #   end
  #
  # end

  context "Factory" do
    before(:all) { @site = Factory(:site) }
    subject { @site.reload }

    its(:user)                          { should be_present }
    its(:plan)                          { should be_present }
    its(:pending_plan)                  { should be_nil }
    its(:hostname)                      { should =~ /jilion[0-9]+\.com/ }
    its(:dev_hostnames)                 { should == "127.0.0.1, localhost" }
    its(:extra_hostnames)               { should be_nil }
    its(:path)                          { should be_nil }
    its(:wildcard)                      { should be_false }
    its(:token)                         { should =~ /^[a-z0-9]{8}$/ }
    its(:license)                       { should_not be_present }
    its(:loader)                        { should_not be_present }
    its(:player_mode)                   { should == "stable" }
    its(:plan_started_at)               { should == Time.now.utc.midnight }
    its(:plan_cycle_started_at)         { should == Time.now.utc.midnight }
    its(:plan_cycle_ended_at)           { should == (Time.now.utc.midnight + 1.month - 1.day).to_datetime.end_of_day }
    its(:pending_plan_started_at)       { should be_nil }
    its(:pending_plan_cycle_started_at) { should be_nil }
    its(:pending_plan_cycle_ended_at)   { should be_nil }
    its(:next_cycle_plan_id)            { should be_nil }

    it { should be_active } # initial state
    it { should be_valid }
  end

  describe "Associations" do
    before(:all) { @site = Factory(:site) }
    subject { @site }

    it { should belong_to :user }
    it { should belong_to :plan }
    it { should have_many :invoices }
    it { should have_many(:invoice_items).through(:invoices) }

    describe "last_invoice" do
      subject { Factory(:site_with_invoice, plan_id: Factory(:plan, price: 123456).id) }

      it "should return the last paid invoice" do
        subject.last_invoice.should == subject.invoices.last
      end
    end

    describe "last_paid_invoice" do
      subject { Factory(:site_with_invoice, plan_id: Factory(:plan, price: 123456).id) }

      it "should return the last paid invoice" do
        subject.last_paid_invoice.should == subject.invoices.paid.last
      end
    end
  end

  describe "Scopes" do
    context "common objects" do
      before(:all) do
        Site.delete_all
        user = Factory(:user)
        # billable
        @site_billable_1 = Factory(:site, user: user, plan_id: @paid_plan.id)
        @site_billable_2 = Factory(:site, user: user, plan_id: @paid_plan.id)
        @site_billable_2.update_attribute(:next_cycle_plan_id, Factory(:plan).id)
        # not billable
        @site_not_billable_1 = Factory(:site, user: user, plan_id: @dev_plan.id)
        @site_not_billable_2 = Factory(:site, user: user, plan_id: @beta_plan.id)
        @site_not_billable_3 = Factory(:site, user: user, plan_id: @paid_plan.id)
        @site_not_billable_3.update_attribute(:next_cycle_plan_id, @dev_plan.id)
        @site_not_billable_4 = Factory(:site, user: user, state: "archived", archived_at: Time.utc(2010,2,28))
        # with path
        @site_with_path = Factory(:site, path: "foo", plan_id: @dev_plan.id)
        # with extra_hostnames
        @site_with_extra_hostnames = Factory(:site, extra_hostnames: "foo.com", plan_id: @paid_plan.id)
      end

      describe "#beta" do
        specify { Site.beta.all.should == [@site_not_billable_2] }
      end

      describe "#dev" do
        specify { Site.dev.order("sites.id").all.should =~ [@site_not_billable_1, @site_with_path] }
      end

      describe "#billable" do
        specify { Site.billable.all.should =~ [@site_billable_1, @site_billable_2, @site_with_extra_hostnames] }
      end

      describe "#not_billable" do
        specify { Site.not_billable.all.should =~ [@site_not_billable_1, @site_not_billable_2, @site_not_billable_3, @site_not_billable_4, @site_with_path] }
      end

      describe "#with_path" do
        specify { Site.with_path.all.should == [@site_with_path] }
      end

      describe "#with_extra_hostnames" do
        specify { Site.with_extra_hostnames.all.should == [@site_with_extra_hostnames] }
      end

      describe "#in_paid_plan" do
        specify { Site.in_paid_plan.all.should =~ [@site_billable_1, @site_billable_2, @site_not_billable_3, @site_not_billable_4, @site_with_extra_hostnames] }
      end
    end

    describe "#to_be_renewed" do
      before(:all) do
        Site.delete_all
        Timecop.travel(2.months.ago) { @site_to_be_renewed = Factory(:site) }
        @site_not_to_be_renewed1 = Factory(:site)
        @site_not_to_be_renewed2 = Factory(:site_with_invoice, plan_started_at: 3.months.ago, plan_cycle_ended_at: 2.months.from_now)
        VCR.use_cassette('ogone/visa_payment_generic') { @site_not_to_be_renewed2.update_attribute(:plan_id, @paid_plan.id) }
      end

      specify { Site.to_be_renewed.all.should == [@site_to_be_renewed] }
    end

    describe "#refundable" do
      before(:all) do
        Site.delete_all
        @site_refundable1 = Factory(:site)
        Timecop.travel(29.days.ago)  { @site_refundable2 = Factory(:site) }
        Timecop.travel(2.months.ago) { @site_not_refundable1 = Factory(:site) }
        @site_not_refundable2 = Factory(:site, refunded_at: Time.now.utc)
      end

      specify { Site.refundable.all.should == [@site_refundable1, @site_refundable2] }
    end
  end

  describe "Validations" do
    subject { Factory(:site) }

    [:hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :plan_id, :user_attributes].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end

    it { should validate_presence_of(:user) }

    it { should allow_value('dev').for(:player_mode) }
    it { should allow_value('beta').for(:player_mode) }
    it { should allow_value('stable').for(:player_mode) }
    it { should_not allow_value('fake').for(:player_mode) }

    specify { Site.validators_on(:hostname).map(&:class).should == [ActiveModel::Validations::PresenceValidator, HostnameValidator, HostnameUniquenessValidator] }
    specify { Site.validators_on(:extra_hostnames).map(&:class).should == [ExtraHostnamesValidator] }
    specify { Site.validators_on(:dev_hostnames).map(&:class).should == [DevHostnamesValidator] }

    describe "plan" do
      context "with no plan" do
        subject { Factory.build(:new_site, plan: nil) }
        it { should_not be_valid }
        it { should have(1).error_on(:plan) }
      end

      context "with no plan but a pending_plan" do
        subject { Factory.build(:new_site, plan: nil, plan_id: @paid_plan.id) }
        its(:pending_plan) { should == @paid_plan }
        it { should be_valid }
      end
    end

    describe "hostname" do
      context "with the dev plan" do
        subject { site = Factory(:site, plan_id: @dev_plan.id); site.hostname = ''; site }
        it { should be_valid }
      end
      context "with the beta plan" do
        subject { site = Factory(:site, plan_id: @beta_plan.id); site.hostname = ''; site }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
      end
      context "with a paid plan" do
        subject { site = Factory(:site, plan_id: @paid_plan.id); site.hostname = ''; site }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
      end
      context "with a pending paid plan" do
        subject { site = Factory(:site_pending, plan_id: @paid_plan.id); site.hostname = ''; site }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
      end
    end

    describe "credit card" do
      context "with the free plan" do
        subject { Factory.build(:site, user: Factory(:user, cc_type: nil, cc_last_digits: nil), plan_id: @dev_plan.id) }
        it { should be_valid }
      end

      context "with any paid plan" do
        context "without credit card" do
          subject do
            site = Factory.build(:new_site, user: Factory(:user_no_cc), plan_id: @paid_plan.id)
            site.save
            site
          end
          it { should_not be_valid }
          it { should have(1).error_on(:base) }
          its(:plan_id) { should be_nil }
          its(:pending_plan_id) { should == @paid_plan.id }
        end

        context "with credit card attributes given" do
          user_attributes = {
            cc_type: 'visa',
            cc_full_name: "Rémy Coutable",
            cc_number: "4111111111111111",
            cc_verification_value: "111",
            cc_expire_on: 2.years.from_now
          }

          subject { Factory.build(:site, user_attributes: valid_cc_attributes, plan_id: @paid_plan.id) }
          it { should be_valid }
        end
      end
    end

    describe "no hostnames at all" do
      context "hostnames are blank & plan is dev plan" do
        subject { Factory.build(:new_site, hostname: nil, extra_hostnames: nil, dev_hostnames: nil, plan: @dev_plan) }
        it { should be_valid } # dev hostnames are set before validation
        it { should have(0).error_on(:base) }
      end

      context "hostnames are blank & plan is not dev plan" do
        subject { Factory.build(:new_site, hostname: nil, extra_hostnames: nil, dev_hostnames: nil, plan: @paid_plan) }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
        it { should have(0).error_on(:base) }
      end
    end

    describe "validates_current_password" do
      context "on a dev plan" do
        subject { Factory(:site, plan_id: @dev_plan.id) }

        it "should not validate current_password when modifying settings" do
          subject.update_attributes(hostname: "newone.com").should be_true
          subject.errors[:base].should be_empty
        end
        it "should not validate current_password when modifying plan" do
          VCR.use_cassette('ogone/visa_payment_generic') { subject.update_attributes(plan_id: @paid_plan.id).should be_true }
          subject.errors[:base].should be_empty
        end
      end

      context "on a paid plan" do
        subject { Factory(:site, plan_id: @paid_plan.id) }

        describe "when updating a site in paid plan" do

          it "needs current_password" do
            subject.update_attributes(plan_id: @custom_plan.token).should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            subject.plan_id.should == @paid_plan.id
            subject.pending_plan_id.should == @custom_plan.id
          end

          it "needs right current_password" do
            subject.update_attributes(plan_id: @custom_plan.token, user_attributes: { current_password: "wrong" }).should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            subject.plan_id.should == @paid_plan.id
            subject.pending_plan_id.should == @custom_plan.id
          end
        end

        describe "when update paid plan settings" do
          it "needs current_password" do
            subject.update_attributes(hostname: "newone.com").should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end

          it "needs right current_password" do
            subject.update_attributes(hostname: "newone.com", user_attributes: { current_password: "wrong" }).should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end

          it "don't need current_password with other errors" do
            subject.update_attributes(hostname: "", email: "").should be_false
            subject.errors[:base].should be_empty
          end
        end

        describe "when downgrade to dev plan" do
          it "needs current_password" do
            subject.update_attributes(plan_id: @dev_plan.id).should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            subject.plan_id.should == @paid_plan.id
            subject.pending_plan_id.should be_nil
            subject.next_cycle_plan_id.should == @dev_plan.id
          end

          it "needs right current_password" do
            subject.update_attributes(plan_id: @dev_plan.id, user_attributes: { :current_password => "wrong" }).should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            subject.plan_id.should == @paid_plan.id
            subject.pending_plan_id.should be_nil
            subject.next_cycle_plan_id.should == @dev_plan.id
          end
        end

        describe "when archive" do
          it "needs current_password" do
            subject.archive.should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end

          it "needs right current_password" do
            subject.user.current_password = 'wrong'
            subject.archive.should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end
        end

        describe "when suspend" do
          it "don't need current_password" do
            subject.suspend.should be_true
            subject.errors[:base].should be_empty
          end
        end
      end
    end # validates_current_password

  end # Validations

  describe "Attributes Accessors" do
    describe "hostname=" do
      %w[ÉCOLE ÉCOLE.fr ÜPPER.de ASDASD.COM 124.123.151.123 mIx3Dd0M4iN.CoM].each do |host|
        it "should downcase hostname: #{host}" do
          site = Factory.build(:new_site, hostname: host)
          site.hostname.should == host.downcase
        end
      end

      it "should clean valid hostname (hostname should never contain /.+://(www.)?/)" do
        site = Factory(:site, hostname: 'http://www.youtube.com?v=31231')
        site.hostname.should == 'youtube.com'
      end

      %w[http://www.youtube.com?v=31231 www.youtube.com?v=31231 youtube.com?v=31231].each do |host|
        it "should clean invalid hostname #{host} (hostname should never contain /.+://(www.)?/)" do
          site = Factory.build(:new_site, hostname: host)
          site.hostname.should == "youtube.com"
        end
      end

      %w[http://www.test,joke;foo test,joke;foo].each do |host|
        it "should clean invalid hostname #{host} (hostname should never contain /.+://(www.)?/)" do
          site = Factory.build(:new_site, hostname: host)
          site.hostname.should_not =~ %r(.+://(www.)?)
        end
      end
    end

    describe "extra_hostnames=" do
      %w[ÉCOLE ÉCOLE.fr ÜPPER.de ASDASD.COM 124.123.151.123 mIx3Dd0M4iN.CoM].each do |host|
        it "should downcase extra_hostnames: #{host}" do
          site = Factory.build(:new_site, extra_hostnames: host)
          site.extra_hostnames.should == host.downcase
        end
      end

      it "should clean valid extra_hostnames (hostname should never contain /.+://(www.)?/)" do
        site = Factory(:site, extra_hostnames: 'http://www.youtube.com?v=31231')
        site.extra_hostnames.should == 'youtube.com'
      end

      %w[http://www.youtube.com?v=31231 www.youtube.com?v=31231 youtube.com?v=31231].each do |host|
        it "should clean invalid extra_hostnames #{host} (extra_hostnames should never contain /.+://(www.)?/)" do
          site = Factory.build(:new_site, extra_hostnames: host)
          site.extra_hostnames.should == "youtube.com"
        end
      end

      it "should clean valid extra_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory(:site, extra_hostnames: 'http://www.jime.org:3000, 33.123.0.1:3000')
        site.extra_hostnames.should == '33.123.0.1, jime.org'
      end
    end

    describe "dev_hostnames=" do
      it "should downcase dev_hostnames" do
        dev_host = "127.]BOO[, JOKE;foo, LOCALHOST, test;ERR"
        site = Factory.build(:new_site, dev_hostnames: dev_host)
        site.dev_hostnames.should == dev_host.downcase
      end

      it "should clean valid dev_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory(:site, dev_hostnames: 'http://www.localhost:3000, 127.0.0.1:3000')
        site.dev_hostnames.should == '127.0.0.1, localhost'
      end

      it "should clean invalid dev_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory.build(:new_site, dev_hostnames: 'http://www.test;err, ftp://127.]boo[:3000, www.joke;foo')
        site.dev_hostnames.should == '127.]boo[, joke;foo, test;err'
      end
    end

    describe "path=" do
      describe "should remove first /" do
        subject { Factory(:site, path: '/users/thibaud') }

        its(:path) { should == 'users/thibaud' }
      end
      describe "should downcase path" do
        subject { Factory(:site, path: '/Users/thibaud') }

        its(:path) { should == 'users/thibaud' }
      end
      describe "should last first /" do
        subject { Factory(:site, path: 'users/thibaud/') }

        its(:path) { should == 'users/thibaud' }
      end
      describe "should both /" do
        subject { Factory(:site, path: '/users/') }

        its(:path) { should == 'users' }
      end
    end

    describe "plan_id=" do
      before(:all) do
        @paid_plan         = Factory(:plan, name: "planet", cycle: "month", price: 1000)
        @paid_plan2        = Factory(:plan, name: "star",   cycle: "month", price: 5000)
        @paid_plan_yearly  = Factory(:plan, name: "planet", cycle: "year",  price: 10000)
        @paid_plan_yearly2 = Factory(:plan, name: "star",   cycle: "year",  price: 50000)
      end

      describe "when creating with a dev plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan_id: @dev_plan.id)
        end
        subject { @site }

        its(:plan_id)            { should be_nil }
        its(:pending_plan_id)    { should == @dev_plan.id }
        its(:next_cycle_plan_id) { should be_nil }

        describe "should prevent new plan_id update while pending_plan_id is present" do
          before(:all) { subject.plan_id = @paid_plan.id }

          its(:plan_id)            { should be_nil }
          its(:pending_plan_id)    { should == @dev_plan.id }
          its(:next_cycle_plan_id) { should be_nil }
        end
      end

      describe "when creating a with a custom plan (token)" do
        before(:all) do
          @site = Factory.build(:new_site, plan_id: @custom_plan.token)
        end
        subject { @site }

        its(:plan_id)            { should be_nil }
        its(:pending_plan_id)    { should == @custom_plan.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when creating a with a custom plan (id)" do
        before(:all) do
          @site = Factory.build(:new_site, plan_id: @custom_plan.id)
        end
        subject { @site }

        its(:plan_id)            { should be_nil }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from dev plan to monthly plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @dev_plan)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @dev_plan.id }
        its(:pending_plan_id)    { should == @paid_plan.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from dev plan to sponsored" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @dev_plan)
          @site.plan_id = @sponsored_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @dev_plan.id }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from dev plan to yearly plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @dev_plan)
          @site.plan_id = @paid_plan_yearly.id
        end
        subject { @site }

        its(:plan_id)            { should == @dev_plan.id }
        its(:pending_plan_id)    { should == @paid_plan_yearly.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from monthly plan to monthly plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan)
          @site.plan_id = @paid_plan2.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan.id }
        its(:pending_plan_id)    { should == @paid_plan2.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from monthly plan to custom plan (token)" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan)
          @site.plan_id = @custom_plan.token
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan.id }
        its(:pending_plan_id)    { should == @custom_plan.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from monthly plan to custom plan (id)" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan)
          @site.plan_id = @custom_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan.id }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from monthly plan to monthly plan with a next_cycle_plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan, next_cycle_plan: @paid_plan_yearly)
          @site.plan_id = @paid_plan2.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan.id }
        its(:pending_plan_id)    { should == @paid_plan2.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when update to the same monthly plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan, next_cycle_plan: @paid_plan2)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan.id }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from monthly plan to yearly plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan)
          @site.plan_id = @paid_plan_yearly.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan.id }
        its(:pending_plan_id)    { should == @paid_plan_yearly.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from paid plan to sponsored" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan)
          @site.plan_id = @sponsored_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan.id }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when downgrade from monthly plan to dev plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan)
          @site.plan_id = @dev_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan.id }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should == @dev_plan.id }
      end

      describe "when downgrade from monthly plan to monthly plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan2)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan2.id }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should == @paid_plan.id }
      end

      describe "when downgrade from monthly plan to yearly plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan2)
          @site.plan_id = @paid_plan_yearly.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan2.id }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should == @paid_plan_yearly.id }
      end

      describe "when upgrade from yearly plan to yearly plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan_yearly)
          @site.plan_id = @paid_plan_yearly2.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan_yearly.id }
        its(:pending_plan_id)    { should == @paid_plan_yearly2.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when downgrade from yearly plan to dev plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan_yearly)
          @site.plan_id = @dev_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan_yearly.id }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should == @dev_plan.id }
      end

      describe "when downgrade from yearly plan to monthly plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan_yearly)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan_yearly.id }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should == @paid_plan.id }
      end

      describe "when downgrade from yearly plan to yearly plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan: @paid_plan_yearly2)
          @site.plan_id = @paid_plan_yearly.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan_yearly2.id }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should == @paid_plan_yearly.id }
      end
    end

  end

  describe "State Machine" do
    before(:each) { VoxcastCDN.stub(:purge) }

    describe "#suspend" do
      subject do
        site = Factory.build(:new_site)
        site.apply_pending_plan_changes
        @worker.work_off
        site
      end

      it "should clear & purge license & loader" do
        VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
        VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
        subject.suspend
        @worker.work_off
        subject.reload.loader.should_not be_present
        subject.license.should_not be_present
      end
    end

    describe "#unsuspend" do
      subject do
        site = Factory.build(:new_site)
        site.apply_pending_plan_changes
        @worker.work_off
        site
      end

      it "should reset license & loader" do
        VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
        VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
        subject.suspend
        @worker.work_off
        subject.reload.loader.should_not be_present
        subject.license.should_not be_present

        subject.unsuspend
        @worker.work_off
        subject.reload.loader.should be_present
        subject.license.should be_present
      end
    end

    describe "#archive" do
      context "from active state" do
        subject do
          site = Factory(:site)
          @worker.work_off
          site
        end

        it "should clear & purge license & loader and set archived_at" do
          VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
          VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
          subject.user.current_password = '123456'
          lambda { subject.archive }.should change(Delayed::Job, :count).by(1)
          subject.reload.should be_archived
          lambda { @worker.work_off }.should change(Delayed::Job, :count).by(-1)
          subject.reload.loader.should_not be_present
          subject.license.should_not be_present
          subject.archived_at.should be_present
        end
      end
    end
  end

  describe "Versioning" do
    it "should work!" do
      with_versioning do
        site = Factory(:site)
        old_hostname = site.hostname
        site.update_attributes hostname: "bob.com", user_attributes: { 'current_password' => '123456' }
        site.versions.last.reify.hostname.should == old_hostname
      end
    end
  end # Versioning

  describe "Callbacks" do

    describe "before_validation" do
      subject { Factory.build(:new_site, dev_hostnames: nil) }

      describe "#set_user_attributes"  do
        subject { Factory(:user, first_name: "Bob") }

        it "should set only current_password" do
          subject.first_name.should == "Bob"
          site = Factory(:site, user: subject, plan_id: @paid_plan.id)
          site.update_attributes(plan_id: @dev_plan.id, user_attributes: { first_name: "John", 'current_password' => '123456' })
          site.user.first_name.should == "Bob"
          site.user.current_password.should == "123456"
          site.plan_id.should == @paid_plan.id
          site.next_cycle_plan_id.should == @dev_plan.id
        end
      end

      describe "#set_default_dev_hostnames" do
        specify do
          subject.dev_hostnames.should be_nil
          subject.should be_valid
          subject.dev_hostnames.should == Site::DEFAULT_DEV_DOMAINS
        end
      end
    end

    describe "before_save" do
      subject { Factory(:site_with_invoice) }

      describe "#clear_alerts_sent_at" do
        specify do
          subject.should_receive(:clear_alerts_sent_at)
          subject.save
        end
      end

      describe "#pend_plan_changes" do
        context "when pending_plan_id has changed" do
          it "should call #pend_plan_changes" do
            subject.reload
            subject.plan_id = @paid_plan.id
            VCR.use_cassette('ogone/visa_payment_generic') { subject.save_without_password_validation }
            subject.pending_plan_id.should == @paid_plan.id
            subject.reload # apply_pending_plan_changes called
            subject.plan_id.should == @paid_plan.id
            subject.pending_plan_id.should be_nil
          end
        end

        context "when pending_plan_id doesn't change" do
          it "should not call #pend_plan_changes" do
            subject.hostname = 'test.com'
            subject.save_without_password_validation
            subject.pending_plan_id.should be_nil
          end
        end
      end
    end # before_save

    describe "after_save" do
      subject { Factory(:site) }

      describe "#create_and_charge_invoice" do
        it "should call #create_and_charge_invoice" do
          subject.should_receive(:create_and_charge_invoice)
          subject.user.current_password = '123456'
          new_paid_plan = Factory(:plan)
          subject.plan_id = new_paid_plan.id
          VCR.use_cassette('ogone/visa_payment_generic') { subject.save! }
          subject.pending_plan_id.should == new_paid_plan.id
        end
      end
    end

    describe "after_create" do
      it "should delay update_ranks" do
        lambda { Factory(:site) }.should change(Delayed::Job.where(:handler.matches => "%update_ranks%"), :count).by(1)
      end

      it "should update ranks" do
        Timecop.travel(10.minutes.ago) { @site = Factory(:site, hostname: 'sublimevideo.net') }
        VCR.use_cassette('sites/ranks') { @worker.work_off }
        @site.reload.google_rank.should == 0
        @site.alexa_rank.should == 100573
      end
    end # after_create

  end # Callbacks

  describe "Class Methods" do

    describe ".delay_update_last_30_days_counters_for_not_archived_sites" do
      it "should delay update_last_30_days_counters_for_not_archived_sites if not already delayed" do
        expect { Site.delay_update_last_30_days_counters_for_not_archived_sites }.should change(Delayed::Job.where(:handler.matches => '%Site%update_last_30_days_counters_for_not_archived_sites%'), :count).by(1)
      end

      it "should not delay update_last_30_days_counters_for_not_archived_sites if already delayed" do
        Site.delay_update_last_30_days_counters_for_not_archived_sites
        expect { Site.delay_update_last_30_days_counters_for_not_archived_sites }.should change(Delayed::Job.where(:handler.matches => '%Site%update_last_30_days_counters_for_not_archived_sites%'), :count).by(0)
      end
    end # .delay_update_last_30_days_counters_for_not_archived_sites

    describe ".update_last_30_days_counters_for_not_archived_sites" do
      it "should delay itself" do
        Site.should_receive(:delay_update_last_30_days_counters_for_not_archived_sites)
        Site.update_last_30_days_counters_for_not_archived_sites
      end

      it "should call update_last_30_days_counters on each non-archived sites" do
        @active_site = Factory(:site, state: 'active')
        Factory(:site_usage, site_id: @active_site.id, day: Time.utc(2011,1,15).midnight, main_player_hits: 6)
        @archived_site = Factory(:site, state: 'archived')
        Factory(:site_usage, site_id: @archived_site.id, day: Time.utc(2011,1,15).midnight, main_player_hits: 6)
        Timecop.travel(Time.utc(2011,1,31, 12)) do
          Site.update_last_30_days_counters_for_not_archived_sites
          @active_site.reload.last_30_days_main_player_hits_total_count.should == 6
          @archived_site.reload.last_30_days_main_player_hits_total_count.should == 0
        end
      end
    end # .update_last_30_days_counters_for_not_archived_sites

  end # Class Methods

  describe "Instance Methods" do

    describe "#clear_alerts_sent_at" do
      subject { Factory(:site_with_invoice, plan_id: @paid_plan.id) }

      it "should clear *_alert_sent_at dates" do
        subject.touch(:plan_player_hits_reached_notification_sent_at)
        subject.plan_player_hits_reached_notification_sent_at.should be_present
        VCR.use_cassette('ogone/visa_payment_generic') do
          subject.update_attributes(plan_id: @custom_plan.token, user_attributes: { 'current_password' => '123456' })
        end
        subject.apply_pending_plan_changes
        subject.plan_player_hits_reached_notification_sent_at.should be_nil
      end
    end

    describe "#without_password_validation" do
      subject { Factory(:site, hostname: "rymai.com") }

      it "should ask password when not calling this method" do
        subject.hostname.should == "rymai.com"
        subject.hostname = "remy.com"
        subject.save
        subject.should_not be_valid
        subject.should have(1).error_on(:base)
      end

      it "should not ask password when calling this method" do
        subject.hostname.should == "rymai.com"
        subject.hostname = "remy.com"
        subject.without_password_validation { subject.save }
        subject.should have(0).error_on(:base)
        subject.reload.hostname.should == "remy.com"
      end

      it "should return the result of the given block" do
        subject.without_password_validation { "foo" }.should == "foo"
      end
    end

    describe "#save_without_password_validation" do
      subject { Factory(:site, hostname: "rymai.com") }

      it "should ask password when not calling this method" do
        subject.hostname.should == "rymai.com"
        subject.hostname = "remy.com"
        subject.save
        subject.should_not be_valid
        subject.should have(1).error_on(:base)
      end

      it "should not ask password when calling this method" do
        subject.hostname.should == "rymai.com"
        subject.hostname = "remy.com"
        subject.save_without_password_validation
        subject.should have(0).error_on(:base)
        subject.reload.hostname.should == "remy.com"
      end

      it "should return the result of the given block" do
        subject.without_password_validation { "foo" }.should == "foo"
      end
    end

    describe "#sponsor!" do
      context "sponsor a dev plan without next plan" do
        before(:all) { Timecop.travel(1.day.ago) { @site = Factory(:site, plan_id: @dev_plan.id) } }
        subject { @site.reload }

        it "should change plan to sponsored plan" do
          subject.next_cycle_plan_id.should be_nil
          subject.pending_plan_id.should be_nil
          subject.plan_started_at.should be_present
          initial_plan_started_at = subject.plan_started_at
          subject.plan_cycle_started_at.should be_nil
          subject.plan_cycle_ended_at.should be_nil

          subject.sponsor!
          subject.reload

          subject.should be_in_sponsored_plan
          subject.next_cycle_plan_id.should be_nil
          subject.pending_plan_id.should be_nil
          subject.plan_started_at.should be_present
          subject.plan_started_at.should_not == initial_plan_started_at
          subject.plan_cycle_started_at.should be_nil
          subject.plan_cycle_ended_at.should be_nil
        end
      end

      context "sponsor a paid plan without next plan" do
        before(:all) { Timecop.travel(1.day.ago) { @site = Factory(:site) } }
        subject { @site.reload }

        it "should change plan to sponsored plan" do
          subject.next_cycle_plan_id.should be_nil
          subject.pending_plan_id.should be_nil
          subject.plan_started_at.should be_present
          initial_plan_started_at = subject.plan_started_at
          subject.plan_cycle_started_at.should be_present
          subject.plan_cycle_ended_at.should be_present

          subject.sponsor!
          subject.reload

          subject.should be_in_sponsored_plan
          subject.next_cycle_plan_id.should be_nil
          subject.pending_plan_id.should be_nil
          subject.plan_started_at.should be_present
          subject.plan_started_at.should == initial_plan_started_at # same as an upgrade
          subject.plan_cycle_started_at.should be_nil
          subject.plan_cycle_ended_at.should be_nil
        end
      end

      context "sponsor a paid plan with a next plan" do
        before(:all) { Timecop.travel(1.day.ago) { @site = Factory(:site) } }
        subject { @site.reload; @site.next_cycle_plan_id = @dev_plan.id; @site }

        it "should change plan to sponsored plan" do
          subject.next_cycle_plan_id.should be_present
          subject.pending_plan_id.should be_nil
          subject.plan_started_at.should be_present
          initial_plan_started_at = subject.plan_started_at
          subject.plan_cycle_started_at.should be_present
          subject.plan_cycle_ended_at.should be_present

          subject.sponsor!
          subject.reload

          subject.should be_in_sponsored_plan
          subject.next_cycle_plan_id.should be_nil
          subject.pending_plan_id.should be_nil
          subject.plan_started_at.should be_present
          subject.plan_started_at.should == initial_plan_started_at # same as an upgrade
          subject.plan_cycle_started_at.should be_nil
          subject.plan_cycle_ended_at.should be_nil
        end
      end
    end

    describe "#need_path?" do
      it "should be true" do
        site = Factory(:site, hostname: 'web.me.com')
        site.need_path?.should be_true
      end
      it "should be false when path present" do
        site = Factory(:site, hostname: 'web.me.com', path: 'users/thibaud')
        site.need_path?.should be_false
      end
      it "should be false" do
        site = Factory(:site, hostname: 'jilion.com')
        site.need_path?.should be_false
      end
    end

    describe "#update_last_30_days_counters" do
      before(:all) do
        @site = Factory(:site, last_30_days_main_player_hits_total_count: 1)
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2010,12,31).midnight,
          main_player_hits:  6,   main_player_hits_cached:  4,
          extra_player_hits: 5,   extra_player_hits_cached: 5,
          dev_player_hits:   4,   dev_player_hits_cached:   6
        )
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1).midnight,
          main_player_hits:  6,   main_player_hits_cached:  4,
          extra_player_hits: 5,   extra_player_hits_cached: 5,
          dev_player_hits:   4,   dev_player_hits_cached:   6
        )
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,30).midnight,
          main_player_hits:  6,   main_player_hits_cached:  4,
          extra_player_hits: 5,   extra_player_hits_cached: 5,
          dev_player_hits:   4,   dev_player_hits_cached:   6
        )
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,31).midnight,
          main_player_hits:  6,   main_player_hits_cached:  4,
          extra_player_hits: 5,   extra_player_hits_cached: 5,
          dev_player_hits:   4,   dev_player_hits_cached:   6
        )
      end

      it "should update counters of non-archived sites from last 30 days site_usages" do
        Timecop.travel(Time.utc(2011,1,31, 12)) do
          @site.update_last_30_days_counters
          @site.last_30_days_main_player_hits_total_count.should  == 20
          @site.last_30_days_extra_player_hits_total_count.should == 20
          @site.last_30_days_dev_player_hits_total_count.should   == 20
        end
      end
    end

    describe "#current_monthly_billable_usage & #current_percentage_of_plan_used" do
      before(:all) do
        @site = Factory(:site)
      end
      before(:each) do
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,30),
          main_player_hits:  1, main_player_hits_cached:  2,
          extra_player_hits: 3, extra_player_hits_cached: 4,
          dev_player_hits:   4, dev_player_hits_cached:   6
        )
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,3,30),
          main_player_hits:  5, main_player_hits_cached:  6,
          extra_player_hits: 7, extra_player_hits_cached: 8,
          dev_player_hits:   4, dev_player_hits_cached:   6
        )
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,4,30),
        main_player_hits:   9, main_player_hits_cached:  10,
        extra_player_hits: 11, extra_player_hits_cached: 12,
        dev_player_hits:    4, dev_player_hits_cached:    6
        )
      end

      context "with monthly plan" do
        before(:all) do
          @site.unmemoize_all
          @site.plan.cycle            = "month"
          @site.plan.player_hits      = 100
          @site.plan_cycle_started_at = Time.utc(2011,3,20)
          @site.plan_cycle_ended_at   = Time.utc(2011,4,20)
          Timecop.travel(Time.utc(2011,3,25))
        end
        subject { @site }

        its(:current_monthly_billable_usage)          { should == 5 + 6 + 7 + 8 }
        its(:current_percentage_of_plan_used) { should == 26 / 100.0 }
      end

      context "with monthly plan and overage" do
        before(:all) do
          @site.unmemoize_all
          @site.plan.cycle            = "month"
          @site.plan.player_hits      = 10
          @site.plan_cycle_started_at = Time.utc(2011,4,20)
          @site.plan_cycle_ended_at   = Time.utc(2011,5,20)
          Timecop.travel(Time.utc(2011,4,25))
        end
        subject { @site }

        its(:current_monthly_billable_usage)          { should == 9 + 10 + 11 + 12 }
        its(:current_percentage_of_plan_used) { should == 1 }
      end

      context "with yearly plan" do
        before(:all) do
          @site.unmemoize_all
          @site.plan.cycle            = "year"
          @site.plan.player_hits      = 100
          @site.plan_cycle_started_at = Time.utc(2011,1,20)
          @site.plan_cycle_ended_at   = Time.utc(2012,1,20)
          Timecop.travel(Time.utc(2011,3,25))
        end
        after(:all) { Timecop.return }
        subject { @site }

        its(:current_monthly_billable_usage)          { should == 5 + 6 + 7 + 8 }
        its(:current_percentage_of_plan_used) { should == 26 / 100.0 }
      end

      context "with yearly plan (other date)" do
        before(:all) do
          @site.unmemoize_all
          @site.plan.cycle            = "year"
          @site.plan.player_hits      = 1000
          @site.plan_cycle_started_at = Time.utc(2011,1,20)
          @site.plan_cycle_ended_at   = Time.utc(2012,1,20)
          Timecop.travel(Time.utc(2011,1,31))
        end
        after(:all) { Timecop.return }
        subject { @site }

        its(:current_monthly_billable_usage)          { should == 1 + 2 + 3 + 4 }
        its(:current_percentage_of_plan_used) { should == 10 / 1000.0 }
      end
    end

    describe "#current_percentage_of_plan_used" do
      it "should return 0 if plan player_hits is 0" do
        site = Factory(:site, plan_id: @dev_plan.id)
        site.current_percentage_of_plan_used.should == 0
      end
    end

    describe "#plan_month_cycle_started_at & #plan_month_cycle_ended_at" do
      before(:all) { @site = Factory(:site) }

      context "with free plan" do
        before(:all) do
          @site.plan.cycle            = "none"
          @site.plan_started_at       = Time.utc(2011,1,10).midnight
          @site.plan_cycle_started_at = nil
          @site.plan_cycle_ended_at   = nil
          Timecop.travel(Time.utc(2011,4,1))
        end
        after(:all) { Timecop.return }
        subject { @site }

        its(:plan_month_cycle_started_at) { should == Time.utc(2011,3,10).midnight }
        its(:plan_month_cycle_ended_at)   { should == Time.utc(2011,4,9).end_of_day }
      end

      context "with monthly plan" do
        before(:all) do
          @site.plan.cycle            = "month"
          @site.plan_cycle_started_at = Time.utc(2011,1,1).midnight
          @site.plan_cycle_ended_at   = Time.utc(2011,1,31).end_of_day
        end
        subject { @site }

        its(:plan_month_cycle_started_at) { should == Time.utc(2011,1,1).midnight }
        its(:plan_month_cycle_ended_at)   { should == Time.utc(2011,1,31).end_of_day }
      end

      context "with yearly plan" do
        before(:all) do
          @site.plan.cycle            = "year"
          @site.plan_cycle_started_at = Time.utc(2011,1,1).midnight
          @site.plan_cycle_ended_at   = Time.utc(2011,12,31).end_of_day
          Timecop.travel(Time.utc(2011,6,10))
        end
        subject { @site }

        its(:plan_month_cycle_started_at) { should == Time.utc(2011,6,1).midnight }
        its(:plan_month_cycle_ended_at)   { should == Time.utc(2011,6,30).end_of_day }

        after(:all) { Timecop.return }
      end

      context "with yearly plan (other date)" do
        before(:all) do
          @site.plan.cycle            = "year"
          @site.plan_cycle_started_at = Time.utc(2011,2,28).midnight
          @site.plan_cycle_ended_at   = Time.utc(2012,2,27).end_of_day
          Timecop.travel(Time.utc(2012,2,10))
        end
        subject { @site }

        its(:plan_month_cycle_started_at) { should == Time.utc(2012,1,28).midnight }
        its(:plan_month_cycle_ended_at)   { should == Time.utc(2012,2,27).end_of_day }

        after(:all) { Timecop.return }
      end
    end

    describe "#percentage_of_days_over_daily_limit(60)" do
      context "with dev_plan" do
        subject { Factory(:site, plan_id: @dev_plan.id) }

        its(:percentage_of_days_over_daily_limit) { should == 0 }
      end

      context "with paid plan" do
        before(:all) do
          @site = Factory(:site, plan_id: Factory(:plan, player_hits: 30 * 300).id, first_paid_plan_started_at: Time.utc(2011,1,1))
        end

        describe "with 1 historic day and 1 over limit" do
          before(:each) do
            Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1),
              main_player_hits:  100, main_player_hits_cached:  100,
              extra_player_hits: 100, extra_player_hits_cached: 100,
              dev_player_hits:   100, dev_player_hits_cached:   100
            )
            Timecop.travel(Time.utc(2011,1,2))
          end
          subject { @site }

          its(:percentage_of_days_over_daily_limit) { should == 1.0 }

          after(:each) { Timecop.return }
        end

        describe "with 2 historic days and 1 over limit" do
          before(:each) do
            Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1), main_player_hits: 400)
            Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,2), main_player_hits: 300)
            Timecop.travel(Time.utc(2011,1,3))
          end
          subject { @site }

          its(:percentage_of_days_over_daily_limit) { should == 0.5 }

          after(:each) { Timecop.return }
        end

        describe "with 5 historic days and 2 over limit" do
          before(:each) do
            Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1), main_player_hits: 400)
            Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,2), main_player_hits: 300)
            Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,3), main_player_hits: 500)
            Timecop.travel(Time.utc(2011,1,6))
          end
          subject { @site }

          its(:percentage_of_days_over_daily_limit) { should == 2 / 5.0 }

          after(:each) { Timecop.return }
        end

        describe "with >60 historic days and 2 over limit" do
          before(:each) do
            Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1), main_player_hits: 400)
            Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,2,1), main_player_hits: 500)
            Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,3,1), main_player_hits: 500)
            Timecop.travel(Time.utc(2011,4,1))
          end
          subject { @site }

          its(:percentage_of_days_over_daily_limit) { should == (2 / 60.0).round(2) }

          after(:each) { Timecop.return }
        end
      end
    end

  end # Instance Methods

end



# == Schema Information
#
# Table name: sites
#
#  id                                            :integer         not null, primary key
#  user_id                                       :integer
#  hostname                                      :string(255)
#  dev_hostnames                                 :string(255)
#  token                                         :string(255)
#  license                                       :string(255)
#  loader                                        :string(255)
#  state                                         :string(255)
#  archived_at                                   :datetime
#  created_at                                    :datetime
#  updated_at                                    :datetime
#  player_mode                                   :string(255)     default("stable")
#  google_rank                                   :integer
#  alexa_rank                                    :integer
#  path                                          :string(255)
#  wildcard                                      :boolean
#  extra_hostnames                               :string(255)
#  plan_id                                       :integer
#  pending_plan_id                               :integer
#  next_cycle_plan_id                            :integer
#  cdn_up_to_date                                :boolean
#  first_paid_plan_started_at                    :datetime
#  plan_started_at                               :datetime
#  plan_cycle_started_at                         :datetime
#  plan_cycle_ended_at                           :datetime
#  pending_plan_started_at                       :datetime
#  pending_plan_cycle_started_at                 :datetime
#  pending_plan_cycle_ended_at                   :datetime
#  plan_player_hits_reached_notification_sent_at :datetime
#  first_plan_upgrade_required_alert_sent_at     :datetime
#  last_30_days_main_player_hits_total_count     :integer         default(0)
#  last_30_days_extra_player_hits_total_count    :integer         default(0)
#  last_30_days_dev_player_hits_total_count      :integer         default(0)
#
# Indexes
#
#  index_sites_on_created_at                                  (created_at)
#  index_sites_on_hostname                                    (hostname)
#  index_sites_on_last_30_days_dev_player_hits_total_count    (last_30_days_dev_player_hits_total_count)
#  index_sites_on_last_30_days_extra_player_hits_total_count  (last_30_days_extra_player_hits_total_count)
#  index_sites_on_last_30_days_main_player_hits_total_count   (last_30_days_main_player_hits_total_count)
#  index_sites_on_plan_id                                     (plan_id)
#  index_sites_on_user_id                                     (user_id)
#

