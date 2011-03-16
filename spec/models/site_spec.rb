# coding: utf-8
require 'spec_helper'

describe Site do

  context "Factory" do
    before(:all) { @site = Factory(:site) }
    subject { @site }

    its(:user)            { should be_present }
    its(:plan)            { should be_present }
    its(:hostname)        { should =~ /jilion[0-9]+\.com/ }
    its(:dev_hostnames)   { should == "127.0.0.1, localhost" }
    its(:extra_hostnames) { should be_nil }
    its(:path)            { should be_nil }
    its(:wildcard)        { should be_false }
    its(:token)           { should =~ /^[a-z0-9]{8}$/ }
    its(:license)         { should_not be_present }
    its(:loader)          { should_not be_present }
    its(:player_mode)     { should == "stable" }
    its(:plan_started_at) { should == Time.now.utc.midnight }
    its(:plan_cycle_started_at) { should == Time.now.utc.midnight }
    its(:plan_cycle_ended_at)   { should == (Time.now.utc.midnight + 1.month - 1.day).to_datetime.end_of_day }
    its(:next_cycle_plan_id)    { should be_nil }

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
  end

  describe "Scopes" do
    before(:all) do
      Site.delete_all
      user = Factory(:user)
      # billable
      @site_billable_1 = Factory(:site, user: user, plan: @paid_plan)
      @site_billable_2 = Factory(:site, user: user, plan: @paid_plan, next_cycle_plan: Factory(:plan))
      # not billable
      @site_not_billable_1 = Factory(:site, user: user, plan: @dev_plan)
      @site_not_billable_2 = Factory(:site, user: user, plan: @beta_plan)
      @site_not_billable_3 = Factory(:site, user: user, plan: @paid_plan).tap { |s| s.update_attribute(:next_cycle_plan, @dev_plan) }
      @site_not_billable_4 = Factory(:site, user: user, state: "archived", archived_at: Time.utc(2010,2,28))
      # with path
      @site_with_path = Factory(:site, path: "foo", plan: @dev_plan)
      # with extra_hostnames
      @site_with_extra_hostnames = Factory(:site, extra_hostnames: "foo.com", plan: @paid_plan)
    end

    describe "#beta" do
      specify { Site.beta.all.should == [@site_not_billable_2] }
    end

    describe "#dev" do
      specify { Site.dev.order("sites.id").all.should == [@site_not_billable_1, @site_with_path] }
    end

    describe "#billable" do
      specify { Site.billable.all.should == [@site_billable_1, @site_billable_2, @site_with_extra_hostnames] }
    end

    describe "#not_billable" do
      specify { Site.not_billable.all.should == [@site_not_billable_1, @site_not_billable_2, @site_not_billable_3, @site_not_billable_4, @site_with_path] }
    end

    describe "#to_be_renewed" do
      before(:each) do
        Timecop.travel(2.months.ago) do
          @site_to_be_renewed = Factory(:site)
        end
        Timecop.travel(2.months.from_now) do
          @site_not_to_be_renewed = Factory(:site)
        end
      end

      specify { Site.to_be_renewed.all.should == [@site_to_be_renewed] }
    end

    describe "#with_path" do
      specify { Site.with_path.all.should == [@site_with_path] }
    end

    describe "#with_extra_hostnames" do
      specify { Site.with_extra_hostnames.all.should == [@site_with_extra_hostnames] }
    end

  end

  describe "Validations" do
    subject { Factory(:site) }

    [:hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :plan_id, :user_attributes].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end

    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:plan).with_message("Please choose a plan") }

    it { should allow_value('dev').for(:player_mode) }
    it { should allow_value('beta').for(:player_mode) }
    it { should allow_value('stable').for(:player_mode) }
    it { should_not allow_value('fake').for(:player_mode) }

    specify { Site.validators_on(:hostname).map(&:class).should == [ActiveModel::Validations::PresenceValidator, HostnameValidator, HostnameUniquenessValidator] }
    specify { Site.validators_on(:extra_hostnames).map(&:class).should == [ExtraHostnamesValidator] }
    specify { Site.validators_on(:dev_hostnames).map(&:class).should == [DevHostnamesValidator] }

    describe "hostname" do
      context "with the dev plan" do
        subject { Factory.build(:site, hostname: nil, plan: @dev_plan) }
        it { should be_valid }
      end
      context "with the beta plan" do
        subject { Factory.build(:site, hostname: nil, plan: @beta_plan) }
        it { should be_valid }
      end
      context "with any other plan than the dev plan" do
        subject { Factory.build(:site, hostname: nil, plan: @paid_plan) }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
      end
    end

    describe "credit card" do
      context "with the dev plan" do
        subject { Factory.build(:site, user: Factory(:user, cc_type: nil, cc_last_digits: nil), plan: @dev_plan) }
        it { should be_valid }
      end
      context "with any other plan than the dev plan" do
        subject { Factory.build(:site, user: Factory(:user, cc_type: nil, cc_last_digits: nil), plan: @paid_plan) }
        it { should_not be_valid }
        it { should have(1).error_on(:base) }
      end
    end

    describe "no hostnames at all" do
      context "hostnames are blank & plan is dev plan" do
        subject { Factory.build(:site, hostname: nil, extra_hostnames: nil, dev_hostnames: nil, plan: @dev_plan) }
        it { should_not be_valid }
        it { should have(1).error_on(:base) }
      end

      context "hostnames are blank & plan is not dev plan" do
        subject { Factory.build(:site, hostname: nil, extra_hostnames: nil, dev_hostnames: nil, plan: @paid_plan) }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
        it { should have(0).error_on(:base) }
      end
    end

    context "when update paid plan settings" do
      subject { Factory(:site, plan: @paid_plan) }

      it "should validate current_password presence" do
        subject.update_attributes(:hostname => "newone.com").should be_false
        subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
      end

      it "should validate current_password" do
        subject.update_attributes(:hostname => "newone.com", :user_attributes => { :current_password => "wrong" }).should be_false
        subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
      end

      it "should not validate current_password with other errors" do
        subject.update_attributes(:hostname => "", :email => '').should be_false
        subject.errors[:base].should be_empty
      end
    end

    context "when update dev plan settings" do
      subject { Factory(:site, plan: @dev_plan) }

      it "should not validate current_password" do
        subject.update_attributes(:hostname => "newone.com").should be_true
        subject.errors[:base].should be_empty
      end
    end

    context "when update dev plan to paid plan" do
      subject { Factory(:site, plan: @dev_plan).reload }

      it "should not validate current_password" do
        subject.update_attributes(:plan_id => @paid_plan.id).should be_true
        subject.errors[:base].should be_empty
      end
    end

    context "when update paid plan to dev plan" do
      subject { Factory(:site, plan: @paid_plan).reload }

      it "should validate current_password presence" do
        subject.update_attributes(:plan_id => @dev_plan.id).should be_false
        subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
      end

      it "should validate current_password" do
        subject.update_attributes(:plan_id => @dev_plan.id, :user_attributes => { :current_password => "wrong" }).should be_false
        subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
      end
    end

    context "when archive with paid plan" do
      subject { Factory(:site, plan: @paid_plan) }

      it "should validate current_password presence" do
        subject.archive.should be_false
        subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
      end

      it "should validate current_password" do
        subject.user.current_password = 'wrong'
        subject.archive.should be_false
        subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
      end
    end

    context "when suspend with paid plan" do
      subject { Factory(:site, plan: @paid_plan) }

      it "should not validate current_password presence" do
        subject.suspend.should be_true
        subject.errors[:base].should be_empty
      end
    end
  end

  describe "Attributes Accessors" do
    describe "hostname=" do
      %w[ÉCOLE ÉCOLE.fr ÜPPER.de ASDASD.COM 124.123.151.123 mIx3Dd0M4iN.CoM].each do |host|
        it "should downcase hostname: #{host}" do
          site = Factory.build(:site, hostname: host)
          site.hostname.should == host.downcase
        end
      end

      it "should clean valid hostname (hostname should never contain /.+://(www.)?/)" do
        site = Factory(:site, hostname: 'http://www.youtube.com?v=31231')
        site.hostname.should == 'youtube.com'
      end

      %w[http://www.youtube.com?v=31231 www.youtube.com?v=31231 youtube.com?v=31231].each do |host|
        it "should clean invalid hostname #{host} (hostname should never contain /.+://(www.)?/)" do
          site = Factory.build(:site, hostname: host)
          site.hostname.should == "youtube.com"
        end
      end

      %w[http://www.test,joke;foo test,joke;foo].each do |host|
        it "should clean invalid hostname #{host} (hostname should never contain /.+://(www.)?/)" do
          site = Factory.build(:site, hostname: host)
          site.hostname.should_not =~ %r(.+://(www.)?)
        end
      end
    end

    describe "extra_hostnames=" do
      %w[ÉCOLE ÉCOLE.fr ÜPPER.de ASDASD.COM 124.123.151.123 mIx3Dd0M4iN.CoM].each do |host|
        it "should downcase extra_hostnames: #{host}" do
          site = Factory.build(:site, extra_hostnames: host)
          site.extra_hostnames.should == host.downcase
        end
      end

      it "should clean valid extra_hostnames (hostname should never contain /.+://(www.)?/)" do
        site = Factory(:site, extra_hostnames: 'http://www.youtube.com?v=31231')
        site.extra_hostnames.should == 'youtube.com'
      end

      %w[http://www.youtube.com?v=31231 www.youtube.com?v=31231 youtube.com?v=31231].each do |host|
        it "should clean invalid extra_hostnames #{host} (extra_hostnames should never contain /.+://(www.)?/)" do
          site = Factory.build(:site, extra_hostnames: host)
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
        site = Factory.build(:site, dev_hostnames: dev_host)
        site.dev_hostnames.should == dev_host.downcase
      end

      it "should clean valid dev_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory(:site, dev_hostnames: 'http://www.localhost:3000, 127.0.0.1:3000')
        site.dev_hostnames.should == '127.0.0.1, localhost'
      end

      it "should clean invalid dev_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory.build(:site, dev_hostnames: 'http://www.test;err, ftp://127.]boo[:3000, www.joke;foo')
        site.dev_hostnames.should == '127.]boo[, joke;foo, test;err'
      end
    end

    describe "path=" do
      it "should remove first /" do
        site = Factory(:site, path: '/users/thibaud')
        site.path.should == 'users/thibaud'
      end
    end

    describe "plan_id=" do
      before(:all) do
        @paid_plan         = Factory(:plan, cycle: "month", price: 1000)
        @paid_plan2        = Factory(:plan, cycle: "month", price: 5000)
        @paid_plan_yearly  = Factory(:plan, cycle: "year",  price: 10000)
        @paid_plan_yearly2 = Factory(:plan, cycle: "year",  price: 50000)
      end

      describe "when upgrade from dev plan to monthly plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @dev_plan)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from dev plan to yearly plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @dev_plan)
          @site.plan_id = @paid_plan_yearly.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan_yearly.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from monthly plan to monthly plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @paid_plan)
          @site.plan_id = @paid_plan2.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan2.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when update to the same monthly plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @paid_plan, next_cycle_plan: @paid_plan2)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when upgrade from monthly plan to yearly plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @paid_plan)
          @site.plan_id = @paid_plan_yearly.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan_yearly.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when downgrade from monthly plan to dev plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @paid_plan)
          @site.plan_id = @dev_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan.id }
        its(:next_cycle_plan_id) { should == @dev_plan.id }
      end

      describe "when downgrade from monthly plan to monthly plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @paid_plan2)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan2.id }
        its(:next_cycle_plan_id) { should == @paid_plan.id }
      end

      describe "when downgrade from monthly plan to yearly plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @paid_plan2)
          @site.plan_id = @paid_plan_yearly.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan2.id }
        its(:next_cycle_plan_id) { should == @paid_plan_yearly.id }
      end

      describe "when upgrade from yearly plan to yearly plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @paid_plan_yearly)
          @site.plan_id = @paid_plan_yearly2.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan_yearly2.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when downgrade from yearly plan to dev plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @paid_plan_yearly)
          @site.plan_id = @dev_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan_yearly.id }
        its(:next_cycle_plan_id) { should == @dev_plan.id }
      end

      describe "when downgrade from yearly plan to monthly plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @paid_plan_yearly)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan_yearly.id }
        its(:next_cycle_plan_id) { should == @paid_plan.id }
      end

      describe "when downgrade from yearly plan to yearly plan" do
        before(:all) do
          @site = Factory.build(:site, plan: @paid_plan_yearly2)
          @site.plan_id = @paid_plan_yearly.id
        end
        subject { @site }

        its(:plan_id)            { should == @paid_plan_yearly2.id }
        its(:next_cycle_plan_id) { should == @paid_plan_yearly.id }
      end
    end
  end

  describe "State Machine" do
    before(:each) { VoxcastCDN.stub(:purge) }

    describe "#suspend" do
      subject do
        site = Factory(:site)
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
        site = Factory(:site)
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
        site.update_attributes hostname: "bob.com", user_attributes: { current_password: '123456' }
        site.versions.last.reify.hostname.should == old_hostname
      end
    end
  end # Versioning

  describe "Callbacks" do

    describe "before_validation" do
      subject { Factory.build(:site, plan: @paid_plan) }

      specify do
        subject.should_receive(:set_user_attributes)
        subject.valid?
      end
    end # before_validation

    describe "before_save" do
      subject { Factory(:site, plan: @paid_plan) }

      specify do
        subject.should_receive(:clear_alerts_sent_at)
        subject.save
      end

      context "when plan has changed" do
        it "should call #update_cycle_plan" do
          subject.should_receive(:update_cycle_plan)
          subject.user.current_password = '123456'
          subject.plan = Factory(:plan)
          subject.save
        end
      end

      context "when plan doesn't change" do
        subject { Factory(:site, plan: @paid_plan) }

        it "should not call #update_cycle_plan" do
          subject.should_not_receive(:update_cycle_plan)
          subject.hostname = 'test.com'
          subject.save
        end
      end
    end # before_save

    describe "after_create" do
      it "should delay update_ranks" do
        lambda { Factory(:site) }.should change(Delayed::Job.where(:handler.matches => "%update_ranks%"), :count).by(1)
      end

      it "should update ranks" do
        Timecop.travel(10.minutes.ago) do
          @site = Factory(:site, hostname: 'sublimevideo.net')
        end
        VCR.use_cassette('sites/ranks') do
          @worker.work_off
        end
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

    describe "#set_user_attributes" do
      subject { Factory(:user, first_name: "Bob") }

      it "should set user_attributes" do
        Factory(:site, user: subject, plan: @paid_plan, user_attributes: { first_name: "John" })
        subject.reload.first_name.should == "John"
      end

      it "should not set user_attributes if site is not in paid plan" do
        Factory(:site, user: subject, plan: @dev_plan, user_attributes: { first_name: "John" })
        subject.reload.first_name.should == "Bob"
      end
    end

    describe "#clear_alerts_sent_at" do
      subject { Factory(:site, plan: @paid_plan) }

      pending "should clear *_alert_sent_at dates" do
        subject.touch(:plan_player_hits_reached_alert_sent_at)
        subject.plan_player_hits_reached_alert_sent_at.should be_present
        subject.plan = @dev_plan
        subject.save
        subject.plan_player_hits_reached_alert_sent_at.should be_nil
      end

    end

    pending "#plan_player_hits_reached_alerted_this_month?" do
      it "should return true when plan_player_hits_reached_alert_sent_at happened durring the current month" do
        site = Factory.build(:site, plan_player_hits_reached_alert_sent_at: Time.now.utc)
        site.should be_plan_player_hits_reached_alerted_this_month
      end
      it "should return false when plan_player_hits_reached_alert_sent_at happened durring the last month" do
        site = Factory.build(:site, plan_player_hits_reached_alert_sent_at: Time.now.utc - 1.month)
        site.should_not be_plan_player_hits_reached_alerted_this_month
      end
      it "should return false when plan_player_hits_reached_alert_sent_at is nil" do
        site = Factory.build(:site, plan_player_hits_reached_alert_sent_at: nil)
        site.should_not be_plan_player_hits_reached_alerted_this_month
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

    describe "#current_billable_usage" do
      before(:all) do
        @site = Factory(:site, plan: Factory(:plan, player_hits: 100))
        Factory(:site_usage, site_id: @site.id, day: Time.now.utc,
          main_player_hits:  6, main_player_hits_cached:  4,
          extra_player_hits: 5, extra_player_hits_cached: 5,
          dev_player_hits:   4, dev_player_hits_cached:   6
        )
        Factory(:site_usage, site_id: @site.id, day: Time.now.utc.tomorrow,
          main_player_hits:  6, main_player_hits_cached:  4,
          extra_player_hits: 5, extra_player_hits_cached: 5,
          dev_player_hits:   4, dev_player_hits_cached:   6
        )
        Factory(:site_usage, site_id: @site.id, day: 2.months.ago,
          main_player_hits:  6, main_player_hits_cached:  4,
          extra_player_hits: 5, extra_player_hits_cached: 5,
          dev_player_hits:   4, dev_player_hits_cached:   6
        )
      end

      it "should update counters of non-archived sites from last 30 days site_usages" do
        @site.current_billable_usage.should == 40
      end
    end

    describe "#current_percentage_of_plan_used" do
      context "with usages less than the plan's limit" do
        before(:all) do
          @site = Factory(:site, plan: Factory(:plan, player_hits: 100))
          Factory(:site_usage, site_id: @site.id, day: Time.now.utc,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
          Factory(:site_usage, site_id: @site.id, day: Time.now.utc.tomorrow,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
          Factory(:site_usage, site_id: @site.id, day: 2.months.ago,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
        end

        it "should update counters of non-archived sites from last 30 days site_usages" do
          @site.current_billable_usage.should == 40
          @site.current_percentage_of_plan_used.should == 0.4
        end
      end

      context "with usages more than the plan's limit" do
        before(:all) do
          @site = Factory(:site, plan: Factory(:plan, player_hits: 30))
          Factory(:site_usage, site_id: @site.id, day: Time.now.utc,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
          Factory(:site_usage, site_id: @site.id, day: Time.now.utc.tomorrow,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
          Factory(:site_usage, site_id: @site.id, day: 2.months.ago,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
        end

        it "should update counters of non-archived sites from last 30 days site_usages" do
          @site.current_billable_usage.should == 40
          @site.current_percentage_of_plan_used.should == 1
        end

      end

      it "should return 0 if plan player_hits is 0" do
        site = Factory(:site, plan: @dev_plan)
        site.current_percentage_of_plan_used.should == 0
      end
    end

  end
end


# == Schema Information
#
# Table name: sites
#
#  id                                         :integer         not null, primary key
#  user_id                                    :integer
#  hostname                                   :string(255)
#  dev_hostnames                              :string(255)
#  token                                      :string(255)
#  license                                    :string(255)
#  loader                                     :string(255)
#  state                                      :string(255)
#  archived_at                                :datetime
#  created_at                                 :datetime
#  updated_at                                 :datetime
#  player_mode                                :string(255)     default("stable")
#  google_rank                                :integer
#  alexa_rank                                 :integer
#  path                                       :string(255)
#  wildcard                                   :boolean
#  extra_hostnames                            :string(255)
#  plan_id                                    :integer
#  cdn_up_to_date                             :boolean
#  plan_started_at                            :datetime
#  plan_cycle_started_at                      :datetime
#  plan_cycle_ended_at                        :datetime
#  next_cycle_plan_id                         :integer
#  plan_player_hits_reached_alert_sent_at     :datetime
#  last_30_days_main_player_hits_total_count  :integer         default(0)
#  last_30_days_extra_player_hits_total_count :integer         default(0)
#  last_30_days_dev_player_hits_total_count   :integer         default(0)
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

