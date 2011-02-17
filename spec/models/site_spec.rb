# coding: utf-8
require 'spec_helper'

describe Site do
  before(:all) do
    @worker = Delayed::Worker.new
    @dev_plan = Factory(:dev_plan)
    @beta_plan = Factory(:beta_plan)
    @paid_plan = Factory(:plan)
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

    it { should be_active }
    it { should be_valid }
  end

  describe "Associations" do
    before(:all) { @site = Factory(:site) }
    subject { @site }

    it { should belong_to :user }
    it { should belong_to :plan }
    it { should have_many :invoice_items }
    it { should have_many(:invoices).through(:invoice_items) }
    it { should have_many(:lifetimes) }
  end

  describe "Scopes" do

    describe "#billable", :focus => true do
      before(:all) do
        user = Factory(:user)
        # billable
        @site1 = Factory(:site, user: user, plan: @paid_plan)
        @site2 = Factory(:site, user: user, plan: @paid_plan, next_cycle_plan: Factory(:plan))
        # not billable
        @site3 = Factory(:site, user: user, plan: @dev_plan)
        @site4 = Factory(:site, user: user, plan: @beta_plan)
        @site5 = Factory(:site, user: user, plan: @paid_plan, next_cycle_plan: @dev_plan)
        @site6 = Factory(:site, user: user, state: "archived", archived_at: Time.utc(2010,2,28))
      end

      specify { Site.billable.should == [@site1, @site2] }
    end

  end

  describe "Validations" do
    subject { Factory(:site) }

    [:hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :plan_id, :user_attributes].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end

    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:plan) }

    it { should allow_value('dev').for(:player_mode) }
    it { should allow_value('beta').for(:player_mode) }
    it { should allow_value('stable').for(:player_mode) }
    it { should_not allow_value('fake').for(:player_mode) }

    specify { Site.validators_on(:hostname).map(&:class).should == [ActiveModel::Validations::PresenceValidator, HostnameUniquenessValidator, HostnameValidator] }
    specify { Site.validators_on(:extra_hostnames).map(&:class).should == [ExtraHostnamesValidator] }
    specify { Site.validators_on(:dev_hostnames).map(&:class).should == [DevHostnamesValidator] }

    describe "hostname" do
      context "with the dev plan" do
        subject { Factory.build(:site, hostname: nil, plan: @dev_plan) }
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

    pending "#rollback" do
      context "from beta state" do
        subject do
          Timecop.travel(10.days.ago)
          site = Factory(:site, plan_id: nil, hostname: "jilion.com", extra_hostnames: "jilion.staging.com, jilion.org").tap { |s| s.activate }
          Timecop.return
          @worker.work_off # populate license / loader
          site.state = 'beta'
          site.should be_beta
          site.plan_id.should be_nil
          site
        end

        it "should rollback to dev state" do
          subject.should be_beta
          subject.rollback.should be_true
          subject.should be_dev
        end

        it "should update license file" do
          old_license_content = subject.license.read
          subject.rollback.should be_true
          @worker.work_off
          subject.reload.license.read.should_not == old_license_content
        end

        it "should purge loader & license file" do
          VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
          VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
          subject.rollback.should be_true
          @worker.work_off
        end
      end
    end

    pending "#activate" do
      context "from dev state" do
        subject do
          site = Factory(:site, state: 'dev', hostname: "jilion.com", extra_hostnames: "jilion.staging.com, jilion.org")
          @worker.work_off
          site.should be_dev
          site.reload
        end

        it "should set activated_at" do
          subject.activated_at.should be_nil
          subject.activate.should be_true
          subject.activated_at.should be_present
        end

        it "should update license file" do
          old_license_content = subject.license.read
          subject.activate.should be_true
          @worker.work_off
          subject.reload.license.read.should_not == old_license_content
        end

        it "should add extra and main hostnames in license file" do
          subject.license.read.should include("localhost")
          subject.license.read.should_not include("jilion.com")
          subject.license.read.should_not include("jilion.staging.com")
          subject.license.read.should_not include("jilion.org")
          subject.activate.should be_true
          @worker.work_off
          subject.reload.license.read.should include("jilion.com")
          subject.license.read.should include("jilion.staging.com")
          subject.license.read.should include("jilion.org")
        end

        it "should purge loader & license file" do
          VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
          VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
          subject.activate.should be_true
          @worker.work_off
        end
      end

      context "from beta state" do
        subject do
          Timecop.travel(10.days.ago)
          site = Factory(:site, plan_id: nil, hostname: "jilion.com", extra_hostnames: "jilion.staging.com, jilion.org").tap { |s| s.activate }
          Timecop.return
          @worker.work_off # populate license / loader
          site.update_attribute(:state, 'dev')
          site.reload.should be_dev
          site.plan_id.should be_nil
          site
        end

        # activate is not directly called on beta sites, it's fired when site is beta and has a plan_id
        it "should reset activated_at" do
          old_activated_at = subject.activated_at
          subject.state    = 'beta'
          subject.plan_id  = Factory(:plan).id
          subject.save
          subject.reload.plan_id.should be_present
          subject.should be_active
          subject.activated_at.should_not == old_activated_at
        end

        it "should not update license file" do
          old_license_content = subject.license.read
          subject.update_attribute(:plan_id, 1)
          @worker.work_off
          subject.reload.license.read.should == old_license_content
        end

        it "should not purge loader & license file" do
          VoxcastCDN.should_not_receive(:purge)
          subject.update_attribute(:plan_id, 1)
          @worker.work_off
        end
      end
    end

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
  end

  describe "Callbacks" do
    describe "before_validation" do
      it "should set user_attributes" do
        user = Factory(:user, first_name: "Bob")
        site = Factory(:site, user: user, user_attributes: { first_name: "John" })
        user.reload.first_name.should == "John"
      end
    end

    describe "before_save" do
      it "should set cdn_up_to_date to false" do
        Factory(:site).cdn_up_to_date.should be_false
      end

      context "settings has changed" do
        { hostname: "test.com", extra_hostnames: "test.staging.com", dev_hostnames: "test.local", path: "yu", wildcard: true }.each do |attribute, value|
          describe "change on #{attribute}" do
            subject { Factory(:site, hostname: "jilion.com", extra_hostnames: "staging.jilion.com", dev_hostnames: "jilion.local", path: "yo", wildcard: false) }

            it "should set cdn_up_to_date to false" do
              subject.update_attributes(attribute => value)
              subject.cdn_up_to_date.should be_false
            end
          end
        end
      end

      context "when plan change" do
        let(:site) { Factory(:site, plan_id: Factory(:plan).id) }

        it "should clear *_alert_sent_at dates" do
          site.touch(:plan_player_hits_reached_alert_sent_at)
          site.touch(:next_plan_recommended_alert_sent_at)
          site.update_attributes(plan_id: Factory(:plan).id)
          site.plan_player_hits_reached_alert_sent_at.should be_nil
          site.next_plan_recommended_alert_sent_at.should be_nil
        end
      end
    end

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

    end

    describe "after_create" do
      it "should delay update_ranks" do
        lambda { Factory(:site) }.should change(Delayed::Job.where(:handler.matches => "%update_ranks%"), :count).by(1)
      end

      it "should update ranks" do
        Timecop.travel(10.minutes.ago)
        site = Factory(:site, hostname: 'sublimevideo.net')
        Timecop.return
        VCR.use_cassette('sites/ranks') do
          @worker.work_off
        end
        site.reload.google_rank.should == 0
        site.alexa_rank.should == 100573
      end
    end
  end

  describe "Class Methods" do

    describe ".delay_update_last_30_days_counters_for_not_archived_sites" do

      it "should delay update_last_30_days_counters_for_not_archived_sites if not already delayed" do
        expect { Site.delay_update_last_30_days_counters_for_not_archived_sites }.should change(Delayed::Job.where(:handler.matches => '%Site%update_last_30_days_counters_for_not_archived_sites%'), :count).by(1)
      end

      it "should not delay update_last_30_days_counters_for_not_archived_sites if already delayed" do
        Site.delay_update_last_30_days_counters_for_not_archived_sites
        expect { Site.delay_update_last_30_days_counters_for_not_archived_sites }.should change(Delayed::Job.where(:handler.matches => '%Site%update_last_30_days_counters_for_not_archived_sites%'), :count).by(0)
      end

    end

    describe "update_last_30_days_counters_for_not_archived_sites" do

      it "should delay itself" do
        Site.should_receive(:delay_update_last_30_days_counters_for_not_archived_sites)
        Site.update_last_30_days_counters_for_not_archived_sites
      end

      it "should call update_last_30_days_counters on each non-archived sites" do
        @active_site = Factory(:site, state: 'active')
        Factory(:site_usage, site_id: @active_site.id, day: Time.utc(2011,1,15).midnight, main_player_hits: 6)
        @archived_site = Factory(:site, state: 'archived')
        Factory(:site_usage, site_id: @archived_site.id, day: Time.utc(2011,1,15).midnight, main_player_hits: 6)
        Timecop.travel(Time.utc(2011,1,31, 12))
        Site.update_last_30_days_counters_for_not_archived_sites
        @active_site.reload.last_30_days_main_player_hits_total_count.should == 6
        @archived_site.reload.last_30_days_main_player_hits_total_count.should == 0
        Timecop.return
      end

    end

  end

  describe "Instance Methods" do
    describe "#plan_player_hits_reached_alerted_this_month?" do
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
          main_player_hits:  6,   main_player_hits_cached: 4,
          extra_player_hits: 5,   extra_player_hits_cached: 5,
          dev_player_hits:   4,   dev_player_hits_cached: 6
        )
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1).midnight,
          main_player_hits:  6,   main_player_hits_cached: 4,
          extra_player_hits: 5,   extra_player_hits_cached: 5,
          dev_player_hits:   4,   dev_player_hits_cached: 6
        )
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,30).midnight,
          main_player_hits:  6,   main_player_hits_cached: 4,
          extra_player_hits: 5,   extra_player_hits_cached: 5,
          dev_player_hits:   4,   dev_player_hits_cached: 6
        )
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,31).midnight,
          main_player_hits:  6,   main_player_hits_cached: 4,
          extra_player_hits: 5,   extra_player_hits_cached: 5,
          dev_player_hits:   4,   dev_player_hits_cached: 6
        )
      end

      it "should update counters of non-archived sites from last 30 days site_usages" do
        Timecop.travel(Time.utc(2011,1,31, 12))
        @site.update_last_30_days_counters
        @site.last_30_days_main_player_hits_total_count.should  == 20
        @site.last_30_days_extra_player_hits_total_count.should == 20
        @site.last_30_days_dev_player_hits_total_count.should   == 20
        Timecop.return
      end
    end

    describe "#current_billable_usage" do
      before(:all) do
        @site = Factory(:site)
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2010,12,31).midnight,
          main_player_hits:  6, main_player_hits_cached: 4,
          extra_player_hits: 5, extra_player_hits_cached: 5,
          dev_player_hits:   4, dev_player_hits_cached: 6
        )
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1).midnight,
          main_player_hits:  6, main_player_hits_cached: 4,
          extra_player_hits: 5, extra_player_hits_cached: 5,
          dev_player_hits:   4, dev_player_hits_cached: 6
        )
        Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,15).midnight,
          main_player_hits:  6, main_player_hits_cached: 4,
          extra_player_hits: 5, extra_player_hits_cached: 5,
          dev_player_hits:   4, dev_player_hits_cached: 6
        )
      end

      it "should update counters of non-archived sites from last 30 days site_usages" do
        Timecop.travel(Time.utc(2011,1,31,12))
        @site.current_billable_usage.should == 40
        Timecop.return
      end
    end

    describe "#current_percentage_of_plan_used" do
      context "with usages less than the plan's limit" do
        before(:all) do
          @site = Factory(:site, plan: Factory(:plan, player_hits: 100))
          Factory(:site_usage, site_id: @site.id, day: Time.utc(2010,12,31).midnight,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
          Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1).midnight,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
          Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,15).midnight,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
        end

        it "should update counters of non-archived sites from last 30 days site_usages" do
          Timecop.travel(Time.utc(2011,1,31,12))
          @site.current_billable_usage.should == 40
          @site.current_percentage_of_plan_used.should == 0.4
          Timecop.return
        end
      end

      context "with usages more than the plan's limit" do
        before(:all) do
          @site = Factory(:site, plan: Factory(:plan, player_hits: 30))
          Factory(:site_usage, site_id: @site.id, day: Time.utc(2010,12,31).midnight,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
          Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1).midnight,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
          Factory(:site_usage, site_id: @site.id, day: Time.utc(2011,1,15).midnight,
            main_player_hits:  6, main_player_hits_cached:  4,
            extra_player_hits: 5, extra_player_hits_cached: 5,
            dev_player_hits:   4, dev_player_hits_cached:   6
          )
        end

        it "should update counters of non-archived sites from last 30 days site_usages" do
          Timecop.travel(Time.utc(2011,1,31,12))
          @site.current_billable_usage.should == 40
          @site.current_percentage_of_plan_used.should == 1
          Timecop.return
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
#  paid_plan_cycle_started_at                 :datetime
#  paid_plan_cycle_ended_at                   :datetime
#  next_cycle_plan_id                         :integer
#  plan_player_hits_reached_alert_sent_at     :datetime
#  next_plan_recommended_alert_sent_at        :datetime
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

