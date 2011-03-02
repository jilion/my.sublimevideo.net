# coding: utf-8
require 'spec_helper'

describe Site do

  pending "specs for a method to find out the numbers of month to add to the started date without keeping record of the past months count" do
    before(:all) do
      @started_date = Time.utc(2011,1,31)
    end

    it do
      Timecop.travel(2011,2,25) do
        now = Time.now.utc
        years = now.year - @started_date.year
        months = now.month - @started_date.month

        # Date of the started_at 1 month after the initial start
        (@started_date + years.years + months.months).should == Time.utc(2011,2,28)
      end
    end

    it do
      Timecop.travel(2011,3,2) do
        now = Time.now.utc
        years = now.year - @started_date.year
        months = now.month - @started_date.month

        # Date of the started_at 2 months after the initial start
        (@started_date + years.years + months.months).should == Time.utc(2011,3,31)
      end
    end

    it do
      Timecop.travel(2012,2,25) do
        now = Time.now.utc
        years = now.year - @started_date.year
        months = now.month - @started_date.month

        # Date of the started_at 1 year and 1 month after the initial start
        (@started_date + years.years + months.months).should == Time.utc(2012,2,29)
      end
    end

    it do
      Timecop.travel(2012,3,2) do
        now = Time.now.utc
        years = now.year - @started_date.year
        months = now.month - @started_date.month

        # Date of the started_at 1 year and 2 months after the initial start
        (@started_date + years.years + months.months).should == Time.utc(2012,3,31)
      end
    end
  end

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
    its(:paid_plan_cycle_started_at) { should == Time.now.utc.midnight }
    its(:paid_plan_cycle_ended_at)   { should == (Time.now.utc.midnight + 1.month - 1.day).end_of_day }

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
        site.update_attributes hostname: "bob.com"
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
        subject.should_receive(:prepare_cdn_update)
        subject.save
      end

      specify do
        subject.should_receive(:clear_alerts_sent_at)
        subject.save
      end

      context "when plan has changed" do
        it "should call #update_for_next_cycle" do
          subject.should_receive(:update_for_next_cycle)
          subject.plan = Factory(:plan)
          subject.save
        end
      end

      context "when plan doesn't change" do
        subject { Factory(:site, plan: @paid_plan) }

        it "should not call #update_for_next_cycle" do
          subject.should_not_receive(:update_for_next_cycle)
          subject.hostname = 'test.com'
          subject.save
        end
      end
    end # before_save

    describe "after_save" do
      before(:each) { VoxcastCDN.stub(:purge) }

      context "on create" do
        subject { Factory.build(:site) }

        it "should delay update_loader_and_license once" do
          count_before = Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count
          lambda { subject.save }.should change(Delayed::Job, :count).by(3)
          Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count.should == count_before + 1
        end

        it "should update loader and license content" do
          subject.loader.read.should be_nil
          subject.license.read.should be_nil
          subject.save
          @worker.work_off
          subject.reload.loader.read.should be_present
          subject.license.read.should be_present
        end

        it "should set cdn_up_to_date to true" do
          subject.cdn_up_to_date.should be_false
          subject.save
          @worker.work_off
          subject.reload.cdn_up_to_date.should be_true
        end

        it "should not purge loader or license file" do
          VoxcastCDN.should_not_receive(:purge)
          subject.save
          @worker.work_off
        end
      end

      context "on update of settings or state (to dev or active)" do
        describe "attributes that appears in the license" do

          before(:each) do
            PageRankr.stub(:ranks)
          end

          { hostname: "test.com", extra_hostnames: "test.staging.com", dev_hostnames: "test.local", path: "yu", wildcard: true }.each do |attribute, value|
            describe "#{attribute} has changed" do
              subject do
                site = Factory(:site, plan: @dev_plan, hostname: "jilion.com", extra_hostnames: "staging.jilion.com", dev_hostnames: "jilion.local", path: "yo", wildcard: false)
                @worker.work_off
                site.reload
              end

              it "should delay update_loader_and_license once" do
                subject
                lambda { subject.update_attribute(attribute, value) }.should change(Delayed::Job, :count).by(1)
                Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count.should == 1
              end

              it "should update license content with dev_hostnames only when site have a dev plan" do
                old_license_content = subject.license.read
                subject.send("#{attribute}=", value)
                subject.save
                @worker.work_off

                subject.reload
                if attribute == :dev_hostnames
                  subject.license.read.should_not == old_license_content
                  subject.license.read.should include(value.to_s)
                else
                  subject.license.read.should == old_license_content
                  subject.license.read.should_not include(value.to_s)
                end
              end

              it "should update license content with #{attribute} value when site have a paid plan" do
                old_license_content = subject.license.read
                subject.send("#{attribute}=", value)
                subject.plan_id = @paid_plan.id
                subject.save
                @worker.work_off

                subject.reload
                subject.license.read.should_not == old_license_content
                case attribute
                when :hostname, :extra_hostnames, :dev_hostnames
                  subject.license.read.should include(value.to_s)
                when :path
                  subject.license.read.should include("path:yu")
                when :path
                  subject.license.read.should include("wildcard:true")
                end
              end

              it "should purge license on CDN" do
                VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
                subject.update_attribute(attribute, value)
                @worker.work_off
              end
            end
          end
        end

        describe "attributes that appears in the loader" do
          describe "player_mode has changed" do
            subject do
              site = Factory(:site, player_mode: 'dev')
              @worker.work_off
              site.reload
            end

            it "should delay update_loader_and_license once" do
              subject
              lambda { subject.update_attribute(:player_mode, 'beta') }.should change(Delayed::Job, :count).by(1)
              Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count.should == 1
            end

            it "should update loader content" do
              old_loader_content = subject.loader.read
              subject.update_attribute(:player_mode, 'beta')
              @worker.work_off
              subject.reload.loader.read.should_not == old_loader_content
            end

            it "should purge loader on CDN" do
              VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
              subject.update_attribute(:player_mode, 'beta')
              @worker.work_off
            end
          end
        end
      end

    end # after_save

    describe "after_create" do
      it "should delay update_ranks" do
        lambda { Factory(:site) }.should change(Delayed::Job.where(:handler.matches => "%update_ranks%"), :count).by(1)
      end

      it "should update ranks" do
        Timecop.travel(10.minutes.ago) do
          site = Factory(:site, hostname: 'sublimevideo.net')
        end
        VCR.use_cassette('sites/ranks') do
          @worker.work_off
        end
        site.reload.google_rank.should == 0
        site.alexa_rank.should == 100573
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

    describe "#prepare_cdn_update" do
      before(:all) do
        @site = Factory(:site, plan: @paid_plan).tap { |s| s.update_attribute(:cdn_up_to_date, true) }
      end

      context "new record" do
        subject do
          site = Factory.build(:site, plan: @paid_plan)
          site.send :prepare_cdn_update
          site
        end

        its(:cdn_up_to_date) { should be_false }
      end

      context "player_mode changed" do
        subject do
          @site.reload.player_mode = "beta"
          @site.send :prepare_cdn_update
          @site
        end

        its(:cdn_up_to_date) { should be_false }
      end

      context "state changed" do
        subject do
          @site.reload.plan = @dev_plan
          @site.send :prepare_cdn_update
          @site
        end

        its(:cdn_up_to_date) { should be_false }
      end

      { hostname: "test.com", extra_hostnames: "test.staging.com", dev_hostnames: "test.local", path: "yu", wildcard: true }.each do |attribute, value|
        describe "#{attribute} has changed" do
          subject do
            @site.reload.send("#{attribute}=", value)
            @site.send :prepare_cdn_update
            @site
          end

          its(:cdn_up_to_date) { should be_false }
        end
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

    describe "#settings_changed?" do
      subject { Factory(:site) }

      it "should return false if no attribute has changed" do
        subject.should_not be_settings_changed
      end

      { hostname: "jilion.com", extra_hostnames: "test.staging.com", dev_hostnames: "test.local", path: "yu", wildcard: true }.each do |attribute, value|
        it "should return true if #{attribute} has changed" do
          subject.send("#{attribute}=", value)
          subject.should be_settings_changed
        end
      end
    end

    describe "#template_hostnames" do
      before(:all) do
        @site = Factory(:site, plan: @dev_plan, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true)
      end
      subject { @site }

      context "site have dev plan" do
        it "should include only dev hostnames" do
          subject.reload.template_hostnames.should == "'127.0.0.1','localhost'"
        end
      end

      %w[beta paid].each do |plan_name|
        context "site have #{plan_name} plan" do
          it "should include hostname, extra_hostnames, path, wildcard' names & dev_hostnames" do
            subject.plan = instance_variable_get(:"@#{plan_name}_plan")
            subject.template_hostnames.should == "'jilion.com','jilion.net','jilion.org','path:foo','wildcard:true','127.0.0.1','localhost'"
          end
        end
      end
    end

    describe "#set_template" do
      context "license" do
        before(:all) do
          @site = Factory(:site).tap { |s| s.set_template("license") }
        end
        subject { @site }

        it "should set license file with template_hostnames" do
          subject.license.read.should include(subject.template_hostnames)
        end
      end

      context "loader" do
        before(:all) do
          @site = Factory(:site).tap { |s| s.set_template("loader") }
        end
        subject { @site }

        it "should set loader file with token" do
          subject.loader.read.should include(subject.token)
        end

        it "should set loader file with stable player_mode" do
          subject.loader.read.should include("http://cdn.sublimevideo.net/p/sublime.js?t=#{subject.token}")
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

    describe "#referrer_type" do
      context "with versioning" do
        before(:all) do
          @site = with_versioning do
            Timecop.travel(1.day.ago)
            site = Factory(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, jilion.net', dev_hostnames: "localhost, 127.0.0.1")
            Timecop.return
            site.update_attributes(hostname: "jilion.net", extra_hostnames: 'jilion.org, jilion.com', dev_hostnames: "jilion.local, localhost, 127.0.0.1")
            site
          end
        end
        subject { @site }

        it { subject.referrer_type("http://jilion.net").should == "main" }
        it { subject.referrer_type("http://jilion.com").should == "extra" }
        it { subject.referrer_type("http://jilion.org").should == "extra" }
        it { subject.referrer_type("http://jilion.local").should == "dev" }
        it { subject.referrer_type("http://jilion.co.uk").should == "invalid" }

        it { subject.referrer_type("http://jilion.net", 1.day.ago).should == "extra" }
        it { subject.referrer_type("http://jilion.com", 1.day.ago).should == "main" }
        it { subject.referrer_type("http://jilion.org", 1.day.ago).should == "extra" }
        it { subject.referrer_type("http://jilion.local", 1.day.ago).should == "invalid" }
        it { subject.referrer_type("http://jilion.co.uk", 1.day.ago).should == "invalid" }
      end

      context "without wildcard or path" do
        before(:all) do
          @site = Factory(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, staging.jilion.com', dev_hostnames: "jilion.local, localhost, 127.0.0.1")
        end
        subject { @site }

        it { subject.referrer_type("http://jilion.com").should == "main" }
        it { subject.referrer_type("http://jilion.com/test/cool").should == "main" }
        it { subject.referrer_type("https://jilion.com").should == "main" }
        it { subject.referrer_type("http://www.jilion.com").should == "main" }

        it { subject.referrer_type("http://staging.jilion.com").should == "extra" }
        it { subject.referrer_type("http://jilion.org").should == "extra" }

        it { subject.referrer_type("http://jilion.local").should == "dev" }
        it { subject.referrer_type("http://127.0.0.1:3000/super.html").should == "dev" }
        it { subject.referrer_type("http://localhost:3000?genial=com").should == "dev" }

        it { subject.referrer_type("http://blog.jilion.com").should == "invalid" }
        it { subject.referrer_type("http://google.com").should == "invalid" }
        it { subject.referrer_type("google.com").should == "invalid" }
        it { subject.referrer_type("jilion.com").should == "invalid" }
        it { subject.referrer_type("-").should == "invalid" }
        it "should send a notify" do
          Notify.should_receive(:send)
          subject.referrer_type(nil).should == "invalid"
        end
      end

      context "with wildcard" do
        before(:all) do
          @site = Factory(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, jilion.net', dev_hostnames: "jilion.local, localhost, 127.0.0.1", wildcard: true)
        end
        subject { @site }

        it { subject.referrer_type("http://blog.jilion.com").should == "main" }
        it { subject.referrer_type("http://jilion.com").should == "main" }
        it { subject.referrer_type("http://jilion.com/test/cool").should == "main" }
        it { subject.referrer_type("https://jilion.com").should == "main" }
        it { subject.referrer_type("http://www.jilion.com").should == "main" }
        it { subject.referrer_type("http://staging.jilion.com").should == "main" }

        it { subject.referrer_type("http://jilion.org").should == "extra" }
        it { subject.referrer_type("http://jilion.net").should == "extra" }

        it { subject.referrer_type("http://jilion.local").should == "dev" }
        it { subject.referrer_type("http://staging.jilion.local").should == "dev" }
        it { subject.referrer_type("http://127.0.0.1:3000/super.html").should == "dev" }
        it { subject.referrer_type("http://localhost:3000?genial=com").should == "dev" }

        # invalid top-domain
        it { subject.referrer_type("http://google.com").should == "invalid" }
        it { subject.referrer_type("http://superjilion.com").should == "invalid" }
        it { subject.referrer_type("http://superjilion.org").should == "invalid" }
        it { subject.referrer_type("http://superjilion.net").should == "invalid" }
        it { subject.referrer_type("google.com").should == "invalid" }
        it { subject.referrer_type("jilion.com").should == "invalid" }
        it { subject.referrer_type("-").should == "invalid" }
        it "should send a notify" do
          Notify.should_receive(:send)
          subject.referrer_type(nil).should == "invalid"
        end
      end

      context "with path" do
        before(:all) do
          @site = Factory(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, staging.jilion.com', dev_hostnames: "jilion.local, localhost, 127.0.0.1", path: "demo")
        end
        subject { @site }

        it { subject.referrer_type("http://jilion.com/demo").should == "main" }
        it { subject.referrer_type("https://jilion.com/demo").should == "main" }
        it { subject.referrer_type("http://jilion.com/demo/cool").should == "main" }

        it { subject.referrer_type("http://jilion.org/demo").should == "extra" }
        it { subject.referrer_type("http://jilion.org/demo/cool").should == "extra" }
        it { subject.referrer_type("http://staging.jilion.com/demo/cool").should == "extra" }

        it { subject.referrer_type("http://jilion.local").should == "dev" }
        it { subject.referrer_type("http://127.0.0.1:3000/demo/super.html").should == "dev" }
        it { subject.referrer_type("http://localhost:3000/demo?genial=com").should == "dev" }
        it { subject.referrer_type("http://localhost:3000?genial=com").should == "dev" }

        # not registered subdomain, even with good path
        it { subject.referrer_type("http://cool.jilion.local").should == "invalid" }
        it { subject.referrer_type("http://cool.jilion.local/demo").should == "invalid" }
        # wrong path
        it { subject.referrer_type("http://jilion.com/test/cool").should == "invalid" }
        # right path, but not registered main or extra domain but containing main or extra domain in it
        it { subject.referrer_type("http://superjilion.com/demo").should == "invalid" }
        it { subject.referrer_type("http://superjilion.org/demo").should == "invalid" }
        it { subject.referrer_type("http://topstaging.jilion.com/demo").should == "invalid" }
        # not allowed without path
        it { subject.referrer_type("http://jilion.com").should == "invalid" }
        it { subject.referrer_type("http://jilion.org").should == "invalid" }
        it { subject.referrer_type("https://jilion.com").should == "invalid" }
        it { subject.referrer_type("http://www.jilion.com").should == "invalid" }
        it { subject.referrer_type("http://blog.jilion.com").should == "invalid" }
        it { subject.referrer_type("http://google.com").should == "invalid" }
        it { subject.referrer_type("google.com").should == "invalid" }
        it { subject.referrer_type("jilion.com").should == "invalid" }
        it { subject.referrer_type("-").should == "invalid" }
        it "should send a notify" do
          Notify.should_receive(:send)
          subject.referrer_type(nil).should == "invalid"
        end
      end

      context "with wildcard and path" do
        before(:all) do
          @site = Factory(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, jilion.net', dev_hostnames: "jilion.local, localhost, 127.0.0.1", path: "demo", wildcard: true)
        end
        subject { @site }

        it { subject.referrer_type("http://jilion.com/demo").should == "main" }
        it { subject.referrer_type("https://jilion.com/demo").should == "main" }
        it { subject.referrer_type("http://staging.jilion.com/demo").should == "main" }
        it { subject.referrer_type("http://jilion.com/demo/cool").should == "main" }

        it { subject.referrer_type("http://jilion.org/demo").should == "extra" }
        it { subject.referrer_type("http://jilion.net/demo/cool").should == "extra" }

        it { subject.referrer_type("http://staging.jilion.local/demo/top").should == "dev" }
        it { subject.referrer_type("http://127.0.0.1:3000/demo/super.html").should == "dev" }
        it { subject.referrer_type("http://localhost:3000/demo?genial=com").should == "dev" }
        it { subject.referrer_type("http://jilion.local").should == "dev" }
        it { subject.referrer_type("http://cool.jilion.local").should == "dev" }
        it { subject.referrer_type("http://jilion.local").should == "dev" }
        it { subject.referrer_type("http://localhost:3000?genial=com").should == "dev" }

        # right path, but not registered main or extra domain but containing main or extra domain in it
        it { subject.referrer_type("http://superjilion.com/demo").should == "invalid" }
        it { subject.referrer_type("http://superjilion.org/demo").should == "invalid" }
        # not allowed without path
        it { subject.referrer_type("http://blog.jilion.com").should == "invalid" }
        it { subject.referrer_type("http://jilion.com").should == "invalid" }
        it { subject.referrer_type("http://jilion.com/test/cool").should == "invalid" }
        it { subject.referrer_type("https://jilion.com").should == "invalid" }
        it { subject.referrer_type("http://www.jilion.com").should == "invalid" }
        it { subject.referrer_type("http://staging.jilion.com").should == "invalid" }
        it { subject.referrer_type("http://jilion.org").should == "invalid" }
        it { subject.referrer_type("http://jilion.net").should == "invalid" }
        it { subject.referrer_type("http://jilion.com").should == "invalid" }
        it { subject.referrer_type("https://jilion.com").should == "invalid" }
        it { subject.referrer_type("http://www.jilion.com").should == "invalid" }
        it { subject.referrer_type("http://blog.jilion.com").should == "invalid" }
        it { subject.referrer_type("http://google.com").should == "invalid" }
        it { subject.referrer_type("google.com").should == "invalid" }
        it { subject.referrer_type("jilion.com").should == "invalid" }
        it { subject.referrer_type("-").should == "invalid" }
        it "should send a notify" do
          Notify.should_receive(:send)
          subject.referrer_type(nil).should == "invalid"
        end
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

    describe "#reset_paid_plan_initially_started_at" do
      context "with a nil paid_plan_initially_started_at" do
        subject do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @dev_plan) }
          @site
        end

        it "should update paid_plan_initially_started_at" do
          Timecop.travel(Time.utc(2012,12,21)) do
            subject.reload.reset_paid_plan_initially_started_at
            subject.paid_plan_initially_started_at.should be_within(5).of(Time.utc(2012,12,21).midnight)
          end
        end
      end

      context "with a present paid_plan_initially_started_at" do
        subject do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site) }
          @site
        end

        it "should update paid_plan_initially_started_at" do
          Timecop.travel(Time.utc(2012,12,21)) do
            subject.reload.reset_paid_plan_initially_started_at
            subject.paid_plan_initially_started_at.should be_within(5).of(Time.utc(2011,2,28).midnight)
          end
        end
      end
    end

    describe "#update_for_next_cycle" do
      before(:all) do
        @paid_plan2 = Factory(:plan, cycle: "month")
        @paid_plan3 = Factory(:plan, cycle: "year")
      end

      context "with no plan change" do
        context "from a dev plan" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,30)) do
              @site = Factory(:site, plan: @dev_plan)
            end

            @site.paid_plan_cycle_started_at.should be_nil
            @site.paid_plan_cycle_ended_at.should be_nil
            @site.plan.should == @dev_plan

            Timecop.travel(Time.utc(2011,3,3)) do
              @site.reload.update_for_next_cycle
              @site.save
            end
          end

          it "should not update paid plan cycle" do
            @site.paid_plan_cycle_started_at.should be_nil
            @site.paid_plan_cycle_ended_at.should be_nil
          end

          it "should update paid plan and reset next cycle plan" do
            @site.plan.should == @dev_plan
            @site.next_cycle_plan.should be_nil
          end
        end

        context "from a beta plan" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,30)) do
              @site = Factory(:site, plan: @beta_plan)
            end

            @site.paid_plan_cycle_started_at.should be_nil
            @site.paid_plan_cycle_ended_at.should be_nil
            @site.plan.should == @beta_plan

            Timecop.travel(Time.utc(2011,3,3)) do
              @site.reload.update_for_next_cycle
              @site.save
            end
          end

          it "should not update paid plan cycle" do
            @site.paid_plan_cycle_started_at.should be_nil
            @site.paid_plan_cycle_ended_at.should be_nil
          end

          it "should update paid plan and reset next cycle plan" do
            @site.plan.should == @beta_plan
            @site.next_cycle_plan.should be_nil
          end
        end

        context "from a paid plan" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,30)) do
              @site = Factory(:site, plan: @paid_plan)
            end

            @site.paid_plan_cycle_started_at.should == Time.utc(2011,1,30).midnight
            @site.paid_plan_cycle_ended_at.should == Time.utc(2011,2,27).end_of_day
            @site.plan.should == @paid_plan
            @site.next_cycle_plan.should be_nil

            Timecop.travel(Time.utc(2011,3,3)) do
              @site.reload.update_for_next_cycle
              @site.save
            end
          end

          it "should update paid plan cycle" do
            @site.paid_plan_cycle_started_at.should == Time.utc(2011,2,28).midnight
            @site.paid_plan_cycle_ended_at.should == Time.utc(2011,3,29).end_of_day
          end

          it "should update paid plan and reset next cycle plan" do
            @site.plan.should == @paid_plan
            @site.next_cycle_plan.should be_nil
          end
        end
      end

      context "with plan change" do
        context "from a dev plan" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,15)) do
              @site = Factory(:site, plan: @dev_plan)
              @site.update_attribute(:next_cycle_plan_id, @paid_plan.id)
            end

            @site.paid_plan_cycle_started_at.should be_nil
            @site.paid_plan_cycle_ended_at.should be_nil
            @site.plan.should == @dev_plan

            Timecop.travel(Time.utc(2011,1,30)) do
              @site.reset_paid_plan_initially_started_at # fake callback to set paid_plan_initially_started_at to today
              @site.update_for_next_cycle
            end
            @site.paid_plan_initially_started_at.should be_within(5).of(Time.utc(2011,1,30).midnight)
            @site.paid_plan_cycle_started_at.should == Time.utc(2011,1,30).midnight
            @site.paid_plan_cycle_ended_at.should == Time.utc(2011,2,27).end_of_day
          end

          # 2011,1,30 => 2011,2,27
          # 2011,2,28 => 2011,3,29
          # 2011,3,30 => 2011,4,29
          # etc.
          1.upto(13) do |i|
            it "should update paid plan cycle #{i} months after" do
              Timecop.travel(Time.utc(2011,1,30) + i.months + 1.day) do
                @site.update_for_next_cycle
              end
              @site.paid_plan_cycle_started_at.should == (@site.paid_plan_initially_started_at + i.months).midnight
              @site.paid_plan_cycle_ended_at.should == (@site.paid_plan_initially_started_at + (i+1).months - 1.day).end_of_day
            end
          end

          it "should update paid plan and reset next cycle plan" do
            @site.plan.should == @paid_plan
            @site.next_cycle_plan.should be_nil
          end
        end

        context "from a beta plan" do
          before(:all) do
            @site = Factory(:site, plan: @beta_plan)
            @site.update_attribute(:next_cycle_plan_id, @paid_plan.id)

            @site.paid_plan_cycle_started_at.should be_nil
            @site.paid_plan_cycle_ended_at.should be_nil
            @site.plan.should == @beta_plan

            Timecop.travel(Time.utc(2011,1,30)) do
              @site.reset_paid_plan_initially_started_at # fake callback to set paid_plan_initially_started_at to today
              @site.update_for_next_cycle
            end
            @site.paid_plan_initially_started_at.should be_within(5).of(Time.utc(2011,1,30).midnight)
            @site.paid_plan_cycle_started_at.should == Time.utc(2011,1,30).midnight
            @site.paid_plan_cycle_ended_at.should == Time.utc(2011,2,27).end_of_day
          end
          
          1.upto(13) do |i|
            it "should update paid plan cycle #{i} months after" do
              Timecop.travel(Time.utc(2011,1,30) + i.months + 1.day) do
                @site.update_for_next_cycle
              end
              @site.paid_plan_cycle_started_at.should == (@site.paid_plan_initially_started_at + i.months).midnight
              @site.paid_plan_cycle_ended_at.should == (@site.paid_plan_initially_started_at + (i+1).months - 1.day).end_of_day
            end
          end

          it "should update paid plan and reset next cycle plan" do
            @site.plan.should == @paid_plan
            @site.next_cycle_plan.should be_nil
          end
        end

        context "month to month" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,15)) do
              @site = Factory(:site, plan: @paid_plan)
            end
            @site.update_attribute(:next_cycle_plan_id, @paid_plan2.id)
            @paid_plan_initially_started_at = @site.paid_plan_initially_started_at
            @site.paid_plan_cycle_started_at.to_i.should == Time.utc(2011,1,15).midnight.to_i
            @site.paid_plan_cycle_ended_at.to_i.should == Time.utc(2011,2,14).end_of_day.to_i
            @site.plan.should == @paid_plan
            @site.next_cycle_plan.should == @paid_plan2

            Timecop.travel(Time.utc(2011,2,15)) do
              @site.update_for_next_cycle
              @site.save
            end
          end

          it "should update paid plan cycle" do
            @site.paid_plan_initially_started_at.should_not == @paid_plan_initially_started_at
            @site.paid_plan_cycle_started_at.to_i.should == Time.utc(2011,2,15).midnight.to_i
            @site.paid_plan_cycle_ended_at.to_i.should == Time.utc(2011,3,14).end_of_day.to_i
          end

          it "should update paid plan and reset next cycle plan" do
            @site.plan.should == @paid_plan2
            @site.next_cycle_plan.should be_nil
          end
        end

        context "month to year" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,15)) do
              @site = Factory(:site, plan: @paid_plan)
            end
            @site.update_attribute(:next_cycle_plan_id, @paid_plan3.id)
            @paid_plan_initially_started_at = @site.paid_plan_initially_started_at
            @site.paid_plan_cycle_started_at.to_i.should == Time.utc(2011,1,15).midnight.to_i
            @site.paid_plan_cycle_ended_at.to_i.should == Time.utc(2011,2,14).end_of_day.to_i
            @site.plan.should == @paid_plan
            @site.next_cycle_plan.should == @paid_plan3

            Timecop.travel(Time.utc(2011,2,15)) do
              @site.update_for_next_cycle
              @site.save
            end
          end

          it "should update paid plan cycle" do
            @site.paid_plan_initially_started_at.should_not == @paid_plan_initially_started_at
            @site.paid_plan_cycle_started_at.to_i.should == Time.utc(2011,2,15).midnight.to_i
            @site.paid_plan_cycle_ended_at.to_i.should == Time.utc(2012,2,14).end_of_day.to_i
          end

          it "should update paid plan and reset next cycle plan" do
            @site.plan.should == @paid_plan3
            @site.next_cycle_plan.should be_nil
          end
        end

        context "year to month" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,15)) do
              @site = Factory(:site, plan: @paid_plan3)
            end
            @site.update_attribute(:next_cycle_plan_id, @paid_plan.id)
            @paid_plan_initially_started_at = @site.paid_plan_initially_started_at
            @site.paid_plan_cycle_started_at.to_i.should == Time.utc(2011,1,15).midnight.to_i
            @site.paid_plan_cycle_ended_at.to_i.should == Time.utc(2012,1,14).end_of_day.to_i
            @site.plan.should == @paid_plan3
            @site.next_cycle_plan.should == @paid_plan

            Timecop.travel(Time.utc(2012,1,15)) do
              @site.update_for_next_cycle
              @site.save
            end
          end

          it "should update paid plan cycle" do
            @site.paid_plan_initially_started_at.should_not == @paid_plan_initially_started_at
            @site.paid_plan_cycle_started_at.to_i.should == Time.utc(2012,1,15).midnight.to_i
            @site.paid_plan_cycle_ended_at.to_i.should == Time.utc(2012,2,14).end_of_day.to_i
          end

          it "should update paid plan and reset next cycle plan" do
            @site.plan.should == @paid_plan
            @site.next_cycle_plan.should be_nil
          end
        end
      end

    end

    describe "#advance_for_next_cycle_end" do
      context "with a monthly plan" do
        before(:all) do
          @plan = Factory(:plan, cycle: "month")
          @site = Factory(:site)
          @site.paid_plan_initially_started_at.should == Time.now.utc.midnight
        end

        context "when now is less than 1 month after site.paid_plan_initially_started_at" do
          it "should return 0 year + 1 month in advance - 1 day" do
            Timecop.travel(Time.now.utc.midnight + 1.day) do
              @site.send(:advance_for_next_cycle_end, @plan).should == 1.month - 1.day
            end
          end
        end

        1.upto(13) do |i|
          context "when now is #{i} months after site.paid_plan_initially_started_at" do
            it "should return #{i} + 1 months in advance - 1 day" do
              Timecop.travel(Time.now.utc.midnight + i.months + 1.day) do
                # puts @site.paid_plan_initially_started_at
                # puts Time.now.utc.midnight + i.months + 1.day
                # r = @site.send(:advance_for_next_cycle_end, @plan)
                # e = (i + 1).months - 1.day
                # puts "#{r} => #{e}" if e == r
                @site.send(:advance_for_next_cycle_end, @plan).should == (i + 1).months - 1.day
              end
            end
          end
        end
      end

      context "with a yearly plan" do
        before(:all) do
          @plan = Factory(:plan, cycle: "year")
          @site = Factory(:site)
          @site.paid_plan_initially_started_at.should == Time.now.utc.midnight
        end

        context "when now is less than 1 yearly after site.paid_plan_initially_started_at" do
          it "should return 12 months in advance - 1 day" do
            Timecop.travel(Time.now.utc.midnight + 1.day) do
              @site.send(:advance_for_next_cycle_end, @plan).should == 12.months - 1.day
            end
          end
        end

        context "when now is more than 1 year after site.paid_plan_initially_started_at" do
          1.upto(3) do |i|
            it "should return #{i*12 + 12} months in advance - 1 day" do
              Timecop.travel(Time.now.utc.midnight + i.years + 1.day) do
                @site.send(:advance_for_next_cycle_end, @plan).should == (i*12 + 12).months - 1.day
              end
            end
          end
        end
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
#  paid_plan_initially_started_at             :datetime
#  paid_plan_cycle_started_at                 :datetime
#  paid_plan_cycle_ended_at                   :datetime
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

