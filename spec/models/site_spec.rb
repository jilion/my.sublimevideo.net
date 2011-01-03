# coding: utf-8
require 'spec_helper'

describe Site do
  before(:all) { @worker = Delayed::Worker.new }
  
  context "Factory" do
    before(:all) { @site = Factory(:site) }
    subject { @site }
    
    its(:user)            { should be_present }
    its(:plan)            { should be_present }
    its(:hostname)        { should =~ /jilion[0-9]+\.com/ }
    its(:dev_hostnames)   { should == "localhost" }
    its(:extra_hostnames) { should be_nil }
    its(:path)            { should be_nil }
    its(:wildcard)        { should be_false }
    its(:token)           { should =~ /^[a-z0-9]{8}$/ }
    its(:license)         { should_not be_present }
    its(:loader)          { should_not be_present }
    its(:player_mode)     { should == "stable" }
    its(:activated_at)    { should be_nil }
    
    it { should be_dev }
    it { should be_valid }
  end
  
  describe "Associations" do
    before(:all) { @site = Factory(:site) }
    subject { @site }
    
    it { should belong_to :user }
    it { should belong_to :plan }
    it { should have_many :invoice_items }
    it { should have_many(:invoices).through(:invoice_items) }
    it { should have_and_belong_to_many :addons }
    it { should have_many(:lifetimes) }
  end
  
  describe "Scopes" do
    
    describe "#billable" do
      before(:all) do
        user = Factory(:user)
        @site1 = Factory(:site, :user => user, :activated_at => Time.utc(2010,1,15))
        @site2 = Factory(:site, :user => user, :activated_at => Time.utc(2010,2,15))
        @site3 = Factory(:site, :user => user, :activated_at => Time.utc(2010,2,1), :archived_at => Time.utc(2010,2,2))
        @site4 = Factory(:site, :user => user, :activated_at => Time.utc(2010,2,1), :archived_at => Time.utc(2010,2,20))
        @site5 = Factory(:site, :user => user, :activated_at => Time.utc(2010,2,1), :archived_at => Time.utc(2010,2,28))
      end
      
      specify { Site.billable(Time.utc(2010,1,1), Time.utc(2010,1,10)).should == [] }
      specify { Site.billable(Time.utc(2010,1,1), Time.utc(2010,1,25)).should == [@site1] }
      specify { Site.billable(Time.utc(2010,2,5), Time.utc(2010,2,25)).should == [@site1, @site2, @site4, @site5] }
      specify { Site.billable(Time.utc(2010,2,21), Time.utc(2010,2,25)).should == [@site1, @site2, @site5] }
    end
    
  end
  
  describe "Validations" do
    [:hostname, :dev_hostnames].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end
    
    it { should validate_presence_of(:user) }
    
    it { should allow_value('dev').for(:player_mode) }
    it { should allow_value('beta').for(:player_mode) }
    it { should allow_value('stable').for(:player_mode) }
    it { should_not allow_value('fake').for(:player_mode) }
    
    specify { Site.validators_on(:hostname).map(&:class).should == [HostnameUniquenessValidator, HostnameValidator, ActiveModel::Validations::PresenceValidator] }
    specify { Site.validators_on(:extra_hostnames).map(&:class).should == [ExtraHostnamesValidator] }
    specify { Site.validators_on(:dev_hostnames).map(&:class).should == [DevHostnamesValidator] }
    
    describe "hostname" do
      it "should be required if state is active" do
        site = Factory(:site, :hostname => nil)
        site.state = 'active'
        site.should_not be_valid
        site.should have(1).error_on(:hostname)
      end
    end
    
    describe "plan" do
      # TODO: When beta state will be removed, plan should be required for every state
      it "should be required if state is dev" do
        site = Factory.build(:site, :state => 'dev', :plan => nil)
        site.should be_dev
        site.should_not be_valid
        site.should have(1).error_on(:plan)
      end
      # TODO: When beta state will be removed, plan should be required for every state
      it "should be required if state is active" do
        site = Factory.build(:site, :state => 'active', :plan => nil)
        site.should be_active
        site.should_not be_valid
        site.should have(1).error_on(:plan)
      end
    end
    
    it "should require a credit card if state is active" do
      user = Factory(:user, :cc_type => nil, :cc_last_digits => nil)
      site = Factory(:site, :user => user)
      site.state = 'active'
      site.should_not be_valid
      site.should have(1).error_on(:base)
    end
    
    describe "no hostnames at all" do
      it "should require at least one of hostname, dev, or extra domains on creation" do
        site = Factory.build(:site, :hostname => '', :extra_hostnames => '', :dev_hostnames => '')
        site.should_not be_valid
        site.should have(1).error_on(:base)
        site.errors[:base].should == ["Please set at least a development or an extra domain"]
      end
      
      it "should not add an error on base because an error is already added on hostname when blank and site is active" do
        site = Factory(:site, :hostname => "test.com").tap { |s| s.activate }
        site.hostname = nil
        site.dev_hostnames = nil
        site.should_not be_valid
        site.should have(:no).error_on(:base)
      end
    end
  end
  
  describe "Attributes Accessors" do
    describe "hostname=" do
      %w[ÉCOLE ÉCOLE.fr ÜPPER.de ASDASD.COM 124.123.151.123 mIx3Dd0M4iN.CoM].each do |host|
        it "should downcase hostname: #{host}" do
          site = Factory.build(:site, :hostname => host)
          site.hostname.should == host.downcase
        end
      end
      
      it "should clean valid hostname (hostname should never contain /.+://(www.)?/)" do
        site = Factory(:site, :hostname => 'http://www.youtube.com?v=31231')
        site.hostname.should == 'youtube.com'
      end
      
      %w[http://www.youtube.com?v=31231 www.youtube.com?v=31231 youtube.com?v=31231].each do |host|
        it "should clean invalid hostname #{host} (hostname should never contain /.+://(www.)?/)" do
          site = Factory.build(:site, :hostname => host)
          site.hostname.should == "youtube.com"
        end
      end
      
      %w[http://www.test,joke;foo test,joke;foo].each do |host|
        it "should clean invalid hostname #{host} (hostname should never contain /.+://(www.)?/)" do
          site = Factory.build(:site, :hostname => host)
          site.hostname.should_not =~ %r(.+://(www.)?)
        end
      end
    end
    
    describe "extra_hostnames=" do
      %w[ÉCOLE ÉCOLE.fr ÜPPER.de ASDASD.COM 124.123.151.123 mIx3Dd0M4iN.CoM].each do |host|
        it "should downcase extra_hostnames: #{host}" do
          site = Factory.build(:site, :extra_hostnames => host)
          site.extra_hostnames.should == host.downcase
        end
      end
      
      it "should clean valid extra_hostnames (hostname should never contain /.+://(www.)?/)" do
        site = Factory(:site, :extra_hostnames => 'http://www.youtube.com?v=31231')
        site.extra_hostnames.should == 'youtube.com'
      end
      
      %w[http://www.youtube.com?v=31231 www.youtube.com?v=31231 youtube.com?v=31231].each do |host|
        it "should clean invalid extra_hostnames #{host} (extra_hostnames should never contain /.+://(www.)?/)" do
          site = Factory.build(:site, :extra_hostnames => host)
          site.extra_hostnames.should == "youtube.com"
        end
      end
      
      it "should clean valid extra_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory(:site, :extra_hostnames => 'http://www.jime.org:3000, 33.123.0.1:3000')
        site.extra_hostnames.should == '33.123.0.1, jime.org'
      end
    end
    
    describe "dev_hostnames=" do
      it "should downcase dev_hostnames" do
        dev_host = "127.]BOO[, JOKE;foo, LOCALHOST, test;ERR"
        site = Factory.build(:site, :dev_hostnames => dev_host)
        site.dev_hostnames.should == dev_host.downcase
      end
      
      it "should clean valid dev_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory(:site, :dev_hostnames => 'http://www.localhost:3000, 127.0.0.1:3000')
        site.dev_hostnames.should == '127.0.0.1, localhost'
      end
      
      it "should clean invalid dev_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory.build(:site, :dev_hostnames => 'http://www.test;err, ftp://127.]boo[:3000, www.joke;foo')
        site.dev_hostnames.should == '127.]boo[, joke;foo, test;err'
      end
    end
    
    describe "addon_ids=" do
      let(:addon1) { Factory(:addon) }
      let(:addon2) { Factory(:addon) }
      subject { Factory(:site) }
      
      it "should remove blank ids" do
        subject.addon_ids = ["", nil]
        subject.addons.should be_empty
        subject.save
        subject.addons.should be_empty
      end
      
      it "should set new addons" do
        subject.addon_ids = [addon1.id, addon2.id]
        subject.addons.should == [addon1, addon2]
        subject.save
        subject.addons.should == [addon1, addon2]
      end
    end
    
    describe "path=" do
      it "should remove first /" do
        site = Factory(:site, :path => '/users/thibaud')
        site.path.should == 'users/thibaud'
      end
    end
  end
  
  describe "State Machine" do
    before(:each) { VoxcastCDN.stub(:purge) }
    
    describe "#rollback" do
      context "from beta state" do
        subject do
          Timecop.travel(10.days.ago)
          site = Factory(:site, :hostname => "jilion.com", :extra_hostnames => "jilion.staging.com, jilion.org").tap { |s| s.activate }
          Timecop.return
          @worker.work_off # populate license / loader
          
          site.reload.update_attribute(:plan_id, nil) # put site in the a beta state
          site.reload.update_attribute(:state, 'beta')
          
          site.reload.should be_beta
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
    
    describe "#activate" do
      context "from dev state" do
        subject do
          site = Factory(:site, :state => 'dev', :hostname => "jilion.com", :extra_hostnames => "jilion.staging.com, jilion.org")
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
          site = Factory(:site, :hostname => "jilion.com", :extra_hostnames => "jilion.staging.com, jilion.org").tap { |s| s.activate }
          Timecop.return
          @worker.work_off # populate license / loader
          
          site.reload.update_attribute(:plan_id, nil) # put site in the a beta state
          site.reload.update_attribute(:state, 'beta')
          
          site.reload.should be_beta
          site.plan_id.should be_nil
          site
        end
        
        # activate is not directly called on beta sites, it's fired when site is beta and has a plan_id
        it "should reset activated_at" do
          old_activated_at = subject.activated_at
          subject.update_attribute(:plan_id, Plan.first.id)
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
    
    context "with an activated site" do
      describe "#suspend" do
        subject do
          site = Factory(:site).tap { |s| s.activate }
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
          site = Factory(:site).tap { |s| s.activate }
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
            site = Factory(:site).tap { |s| s.activate }
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
        
        context "from beta state" do
          subject do
            site = Factory(:site).tap { |s| s.activate }
            @worker.work_off
            site.reload.update_attribute(:plan_id, nil) # put site in the a beta state
            site.reload.update_attribute(:state, 'beta')
            site.reload.should be_beta
            site.plan_id.should be_nil
            site
          end
          
          it "should clear & purge license & loader and set archived_at" do
            VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
            VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
            lambda { subject.archive }.should change(Delayed::Job, :count).by(1)
            subject.archive
            subject.reload.should be_archived
            lambda { @worker.work_off }.should change(Delayed::Job, :count).by(-1)
            subject.loader.should_not be_present
            subject.license.should_not be_present
            subject.archived_at.should be_present
          end
        end
      end
    end
  end
  
  describe "Versioning" do
    it "should work!" do
      with_versioning do
        site = Factory(:site)
        old_hostname = site.hostname
        site.activate
        site.update_attributes :hostname => "bob.com"
        site.versions.last.reify.hostname.should == old_hostname
      end
    end
  end
  
  describe "Callbacks" do
    describe "before_validation" do
      it "should set user_attributes" do
        user = Factory(:user, :first_name => "Bob")
        site = Factory(:site, :user => user, :user_attributes => { :first_name => "John" })
        user.reload.first_name.should == "John"
      end
    end
    
    describe "before_save" do
      it "should set cdn_up_to_date to false" do
        Factory(:site).cdn_up_to_date.should be_false
      end
      
      context "settings has changed" do
        { :hostname => "test.com", :extra_hostnames => "test.staging.com", :dev_hostnames => "test.local", :path => "yu", :wildcard => true }.each do |attribute, value|
          describe "change on #{attribute}" do
            subject { Factory(:site, :hostname => "jilion.com", :extra_hostnames => "staging.jilion.com", :dev_hostnames => "jilion.local", :path => "yo", :wildcard => false) }
            
            it "should set cdn_up_to_date to false" do
              subject.update_attributes(attribute => value)
              subject.cdn_up_to_date.should be_false
            end
          end
        end
      end
    end
    
    describe "after_save" do
      before(:each) { VoxcastCDN.stub(:purge) }
      
      context "on create" do
        subject { Factory.build(:site) }
        
        it "should delay update_loader_and_license once" do
          count_before = Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count
          lambda { subject.save }.should change(Delayed::Job, :count).by(2)
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
      
      context "on update of settings, addons or state (to dev or active)" do
        describe "attributes that appears in the license" do
          before(:all) do
            @plan = Factory(:plan)
            @addon1 = Factory(:addon, :name => 'ssl', :price => 99)
            @addon2 = Factory(:addon, :name => 'stat', :price => 99)
          end
          
          before(:each) do
            Addon.stub(:find).with([1])   { [@addon1] }
            Addon.stub(:find).with([1,2]) { [@addon1, @addon2] }
            Addon.stub(:find).with(:all)  { [@addon1, @addon2] }
            PageRankr.stub(:ranks)
          end
          
          { :hostname => "test.com", :extra_hostnames => "test.staging.com", :dev_hostnames => "test.local", :path => "yu", :wildcard => true, :addon_ids => [1, 2] }.each do |attribute, value|
            describe "#{attribute} has changed" do
              subject do
                site = Factory(:site, :plan => @plan, :hostname => "jilion.com", :extra_hostnames => "staging.jilion.com", :dev_hostnames => "jilion.local", :path => "yo", :wildcard => false, :addon_ids => [1], :state => 'dev')
                @worker.work_off
                site.reload
              end
              
              it "should delay update_loader_and_license once" do
                subject
                lambda { subject.update_attribute(attribute, value) }.should change(Delayed::Job, :count).by(1)
                Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count.should == 1
              end
              
              it "should update license content with dev_hostnames only when site is dev" do
                old_license_content = subject.license.read
                subject.send("#{attribute}=", value)
                subject.save && @worker.work_off
                
                subject.reload.should be_dev
                if attribute == :dev_hostnames
                  subject.license.read.should_not == old_license_content
                  subject.license.read.should include(value.to_s)
                else
                  subject.license.read.should == old_license_content
                  subject.license.read.should_not include(value.to_s)
                end
              end
              
              it "should update license content with #{attribute} value when site is active" do
                old_license_content = subject.license.read
                subject.send("#{attribute}=", value)
                subject.activate && @worker.work_off
                
                subject.reload.should be_active
                subject.license.read.should_not == old_license_content
                case attribute
                when :hostname, :extra_hostnames, :dev_hostnames
                  subject.license.read.should include(value.to_s)
                when :path
                  subject.license.read.should include("path:yu")
                when :path
                  subject.license.read.should include("wildcard:true")
                when :addon_ids
                  subject.license.read.should include("addons:ssl,stat")
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
              site = Factory(:site, :player_mode => 'dev')
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
        site = Factory(:site, :hostname => 'sublimevideo.net')
        Timecop.return
        VCR.use_cassette('sites/ranks') do
          @worker.work_off
        end
        site.reload.google_rank.should == 0
        site.alexa_rank.should == 100573
      end
    end
  end
  
  describe "Instance Methods" do
    describe "#alerted_this_month?" do
      it "should return true when last_usage_alert_sent_at happened durring the current month" do
        site = Factory.build(:site, :last_usage_alert_sent_at => Time.now.utc)
        site.should be_alerted_this_month
      end
      it "should return false when last_usage_alert_sent_at happened durring the last month" do
        site = Factory.build(:site, :last_usage_alert_sent_at => Time.now.utc - 1.month)
        site.should_not be_alerted_this_month
      end
      it "should return false when last_usage_alert_sent_at is nil" do
        site = Factory.build(:site, :last_usage_alert_sent_at => nil)
        site.should_not be_alerted_this_month
      end
    end
    
    describe "#settings_changed?" do
      subject { Factory(:site) }
      
      it "should return false if no attribute has changed" do
        subject.should_not be_settings_changed
      end
      
      { :hostname => "jilion.com", :extra_hostnames => "test.staging.com", :dev_hostnames => "test.local", :path => "yu", :wildcard => true }.each do |attribute, value|
        it "should return true if #{attribute} has changed" do
          subject.send("#{attribute}=", value)
          subject.should be_settings_changed
        end
      end
    end
    
    describe "#addon_ids_changed?" do
      let(:addon1) { Factory(:addon) }
      let(:addon2) { Factory(:addon) }
      subject { Factory(:site) }
      
      it "should return false if addons hasn't changed" do
        subject.should_not be_addon_ids_changed
      end
      
      it "should return true if addons has changed" do
        subject.addon_ids = [addon1.id, addon2.id]
        subject.should be_addon_ids_changed
      end
    end
    
    describe "#template_hostnames" do
      before(:all) do
        @site = Factory(:site, :hostname => "jilion.com", :extra_hostnames => "jilion.net, jilion.org", :dev_hostnames => '127.0.0.1,localhost', :path => 'foo', :wildcard => true, :addons => [Factory(:addon, :name => 'ssl_gold'), Factory(:addon, :name => 'customization')])
        @site.plan = nil
        @site.save(:validate => false)
      end
      subject { @site }
      
      context "site is not active" do
        it "should include only dev hostnames" do
          subject.reload.template_hostnames.should == "'127.0.0.1','localhost'"
        end
      end
      
      %w[beta active].each do |state|
        context "site is #{state}" do
          it "should include hostname, extra_hostnames, path, wildcard, addons' names & dev_hostnames" do
            subject.reload.update_attribute(:state, state)
            subject.state.should == state
            subject.template_hostnames.should == "'jilion.com','jilion.net','jilion.org','path:foo','wildcard:true','addons:customization,ssl_gold','127.0.0.1','localhost'"
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
        site = Factory(:site, :hostname => 'web.me.com')
        site.need_path?.should be_true
      end
      it "should be false when path present" do
        site = Factory(:site, :hostname => 'web.me.com', :path => 'users/thibaud')
        site.need_path?.should be_false
      end
      it "should be false" do
        site = Factory(:site, :hostname => 'jilion.com')
        site.need_path?.should be_false
      end
    end
    
    describe "#referrer_type" do
      context "with versioning" do
        before(:all) do
          @site = with_versioning do
            Timecop.travel(1.day.ago)
            site = Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, jilion.net', :dev_hostnames => "localhost, 127.0.0.1")
            site.activate
            @worker.work_off
            Timecop.return
            site.reload
            site.update_attributes(:hostname => "jilion.net", :extra_hostnames => 'jilion.org, jilion.com', :dev_hostnames => "jilion.local, localhost, 127.0.0.1")
            @worker.work_off
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
          @site = Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, staging.jilion.com', :dev_hostnames => "jilion.local, localhost, 127.0.0.1")
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
          @site = Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, jilion.net', :dev_hostnames => "jilion.local, localhost, 127.0.0.1", :wildcard => true)
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
          @site = Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, staging.jilion.com', :dev_hostnames => "jilion.local, localhost, 127.0.0.1", :path => "demo")
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
          @site = Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, jilion.net', :dev_hostnames => "jilion.local, localhost, 127.0.0.1", :path => "demo", :wildcard => true)
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
  end
end




# == Schema Information
#
# Table name: sites
#
#  id                       :integer         not null, primary key
#  user_id                  :integer
#  hostname                 :string(255)
#  dev_hostnames            :string(255)
#  token                    :string(255)
#  license                  :string(255)
#  loader                   :string(255)
#  state                    :string(255)
#  archived_at              :datetime
#  created_at               :datetime
#  updated_at               :datetime
#  player_mode              :string(255)     default("stable")
#  google_rank              :integer
#  alexa_rank               :integer
#  path                     :string(255)
#  wildcard                 :boolean
#  extra_hostnames          :string(255)
#  plan_id                  :integer
#  cdn_up_to_date           :boolean
#  activated_at             :datetime
#  last_usage_alert_sent_at :datetime
#
# Indexes
#
#  index_sites_on_created_at  (created_at)
#  index_sites_on_hostname    (hostname)
#  index_sites_on_plan_id     (plan_id)
#  index_sites_on_user_id     (user_id)
#

