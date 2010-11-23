# coding: utf-8
require 'spec_helper'

describe Site do
  # 3.6s
  context "From factory" do
    set(:site_from_factory) { Factory(:site) }
    subject { site_from_factory }
    
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
  
  # 3.2s
  describe "Associations" do
    set(:site_for_associations) { Factory(:site) }
    subject { site_for_associations }
    
    it { should belong_to :user }
    it { should belong_to :plan }
    it { should have_many :invoice_items }
    it { should have_many(:invoices).through(:invoice_items) }
    it { should have_and_belong_to_many :addons }
  end
  
  # TODO 86s
  describe "Validates " do
    [:hostname, :dev_hostnames].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end
    
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:plan).with_message("Please choose a plan") }
    
    it { should allow_value('dev').for(:player_mode) }
    it { should allow_value('beta').for(:player_mode) }
    it { should allow_value('stable').for(:player_mode) }
    it { should_not allow_value('fake').for(:player_mode) }
    
    specify { Site.validators_on(:hostname).map(&:class).should == [HostnameUniquenessValidator, HostnameValidator, ActiveModel::Validations::PresenceValidator] }
    specify { Site.validators_on(:extra_hostnames).map(&:class).should == [ExtraHostnamesValidator] }
    specify { Site.validators_on(:dev_hostnames).map(&:class).should == [DevHostnamesValidator] }
    
    # 15s
    describe "hostname" do
      it "should be required if state is active" do
        site = Factory(:site, :hostname => nil)
        site.state = 'active'
        site.should_not be_valid
        site.should have(1).error_on(:hostname)
      end
    end
    
    # 3.6s
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
    
    describe "ensure that addons exits for current plan" do
      set(:plan1)           { Factory(:plan) }
      set(:plan2)           { Factory(:plan) }
      set(:addon_for_plan1) { Factory(:addon, :addonships_attributes => [{ :plan_id => plan1.id, :price => 99 }]) }
      let(:site)            { Factory(:site, :plan => plan1, :addon_ids => [addon_for_plan1]) }
      
      context "site is dev" do
        before(:each) { site.plan = plan2 }
        
        it "should not add an error" do
          site.should be_valid
          site.should have(:no).error_on(:base)
        end
      end
      
      context "site is active" do
        before(:each) do
          site.update_attribute(:state, 'active')
          site.plan = plan2
        end
        
        it "should not add an error" do
          site.should_not be_valid
          site.should have(1).error_on(:base)
          site.errors[:base].should == ["Add-on '#{addon_for_plan1.name}' is not available for the plan '#{plan2.name}'. Please cancel this add-on before changing your plan."]
        end
      end
    end
  end
  
  # 17.3s
  describe "Attributes Accessors, " do
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
  
  # 17.3s
  describe "State Machine, " do
    before(:each) { VoxcastCDN.stub(:purge) }
    
    describe "activate" do
      subject do
        site = Factory(:site, :hostname => "jilion.com", :extra_hostnames => "jilion.staging.com, jilion.org")
        Delayed::Worker.new(:quiet => true).work_off
        site
      end
      
      it "should set activated_at" do
        subject.activated_at.should be_nil
        subject.activate.should be_true
        subject.activated_at.should be_present
      end
      
      it "should update license file" do
        old_license_content = subject.license.read
        subject.activate.should be_true
        Delayed::Worker.new(:quiet => true).work_off
        subject.reload.license.read.should_not == old_license_content
      end
      
      it "should add extra and main hostnames in license file" do
        subject.license.read.should be_nil
        subject.license.read.should be_nil
        subject.activate.should be_true
        Delayed::Worker.new(:quiet => true).work_off
        subject.reload.license.read.should include("jilion.com")
        subject.license.read.should include("jilion.staging.com")
        subject.license.read.should include("jilion.org")
      end
      
      it "should purge loader & license file" do
        VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
        VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
        subject.activate.should be_true
        Delayed::Worker.new(:quiet => true).work_off
      end
    end
    
    context "with an activated site, " do
      subject do
        site = Factory(:site).tap { |s| s.activate }
        Delayed::Worker.new(:quiet => true).work_off
        site
      end
      
      describe "suspend" do
        it "should clear & purge license & loader" do
          VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
          VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
          subject.suspend
          Delayed::Worker.new(:quiet => true).work_off
          subject.reload.loader.should_not be_present
          subject.license.should_not be_present
        end
      end
      
      describe "unsuspend" do
        it "should reset license & loader" do
          subject.suspend
          Delayed::Worker.new(:quiet => true).work_off
          subject.unsuspend
          Delayed::Worker.new(:quiet => true).work_off
          subject.reload.loader.should be_present
          subject.license.should be_present
        end
      end
      
      describe "archive" do
        it "should clear & purge license & loader and set archived_at" do
          VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
          VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
          subject.archive
          Delayed::Worker.new(:quiet => true).work_off
          subject.reload.loader.should_not be_present
          subject.license.should_not be_present
          subject.archived_at.should be_present
        end
      end
    end
  end
  
  # 3.5s
  describe "Versioning, " do
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
  
  # TODO 64.3s
  describe "Callbacks, " do
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
          Delayed::Worker.new(:quiet => true).work_off
          subject.reload.loader.read.should be_present
          subject.license.read.should be_present
        end
        
        it "should set cdn_up_to_date to true" do
          subject.cdn_up_to_date.should be_false
          subject.save
          Delayed::Worker.new(:quiet => true).work_off
          subject.reload.cdn_up_to_date.should be_true
        end
        
        it "should not purge loader or license file" do
          VoxcastCDN.should_not_receive(:purge)
          subject.save
          Delayed::Worker.new(:quiet => true).work_off
        end
      end
      
      context "on update of settings, addons or state (to dev or active)" do
        describe "attributes that appears in the license" do
          set(:plan)   { Factory(:plan) }
          set(:addon1) { Factory(:addon, :name => 'ssl', :addonships_attributes => [{ :plan_id => plan.id, :price => 99 }]) }
          set(:addon2) { Factory(:addon, :name => 'stat', :addonships_attributes => [{ :plan_id => plan.id, :price => 99 }]) }
          
          before(:each) do
            Addon.stub(:find).with([1])   { [addon1] }
            Addon.stub(:find).with([1,2]) { [addon1, addon2] }
            Addon.stub(:find).with(:all)  { [addon1, addon2] }
            PageRankr.stub(:ranks)
          end
          
          { :hostname => "test.com", :extra_hostnames => "test.staging.com", :dev_hostnames => "test.local", :path => "yu", :wildcard => true, :addon_ids => [1, 2] }.each do |attribute, value|
            describe "#{attribute} has changed" do
              subject do
                site = Factory(:site, :plan => plan, :hostname => "jilion.com", :extra_hostnames => "staging.jilion.com", :dev_hostnames => "jilion.local", :path => "yo", :wildcard => false, :addon_ids => [1], :state => 'dev')
                Delayed::Worker.new(:quiet => true).work_off
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
                subject.save && Delayed::Worker.new(:quiet => true).work_off
                
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
                subject.activate && Delayed::Worker.new(:quiet => true).work_off
                
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
                Delayed::Worker.new(:quiet => true).work_off
              end
            end
          end
        end
        
        describe "attributes that appears in the loader" do
          describe "player_mode has changed" do
            subject do
              site = Factory(:site, :player_mode => 'dev')
              Delayed::Worker.new(:quiet => true).work_off
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
              Delayed::Worker.new(:quiet => true).work_off
              subject.reload.loader.read.should_not == old_loader_content
            end
            
            it "should purge loader on CDN" do
              VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
              subject.update_attribute(:player_mode, 'beta')
              Delayed::Worker.new(:quiet => true).work_off
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
          Delayed::Worker.new(:quiet => true).work_off
        end
        site.reload.google_rank.should == 0
        site.alexa_rank.should  == 108330
      end
    end
  end
  
  # 26.7s
  describe "Instance methods, " do
    describe "settings_changed?" do
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
    
    describe "addons_changed?" do
      let(:addon1) { Factory(:addon) }
      let(:addon2) { Factory(:addon) }
      subject { Factory(:site) }
      
      it "should return false if addons hasn't changed" do
        subject.should_not be_addons_changed
      end
      
      it "should return true if addons has changed" do
        subject.addon_ids = [addon1.id, addon2.id]
        subject.should be_addons_changed
      end
    end
    
    describe "template_hostnames" do
      set(:site_for_template) { Factory(:site, :hostname => "jilion.com", :extra_hostnames => "jilion.net, jilion.org", :dev_hostnames => '127.0.0.1,localhost', :path => 'foo', :wildcard => true, :addons => [Factory(:addon, :name => 'ssl_gold'), Factory(:addon, :name => 'customization')]) }
      
      context "site is not active" do
        it "should include only dev hostnames" do
          site_for_template.template_hostnames.should == "'127.0.0.1','localhost'"
        end
      end
      
      context "site is active" do
        it "should include hostname, extra_hostnames, path, wildcard, addons' names & dev_hostnames" do
          site_for_template.update_attribute(:state, 'active')
          site_for_template.template_hostnames.should == "'jilion.com','jilion.net','jilion.org','path:foo','wildcard:true','addons:customization,ssl_gold','127.0.0.1','localhost'"
        end
      end
    end
    
    describe "set_template" do
      context "license" do
        let(:site_with_set_template_license) { Factory(:site).tap { |s| s.set_template("license") } }
        
        it "should set license file with template_hostnames" do
          site_with_set_template_license.license.read.should include(site_with_set_template_license.template_hostnames)
        end
      end
      context "loader" do
        set(:site_with_set_template_loader) { Factory(:site).tap { |s| s.set_template("loader") } }
        
        it "should set loader file with token" do
          site_with_set_template_loader.loader.read.should include(site_with_set_template_loader.token)
        end
        
        it "should set loader file with stable player_mode" do
          site_with_set_template_loader.loader.read.should include("http://cdn.sublimevideo.net/p/sublime.js?t=#{site_with_set_template_loader.token}")
        end
      end
    end
    
    describe "need_path?" do
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
    
    describe "referrer_type" do
      context "with versioning" do
        # 23s with 'subject' (each), 4s with 'set' (all)
        set(:site_with_versioning) do
          with_versioning do
            Timecop.travel(1.day.ago)
            site = Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, jilion.net', :dev_hostnames => "localhost, 127.0.0.1")
            site.activate
            Delayed::Worker.new(:quiet => true).work_off
            Timecop.return
            site.reload
            site.update_attributes(:hostname => "jilion.net", :extra_hostnames => 'jilion.org, jilion.com', :dev_hostnames => "jilion.local, localhost, 127.0.0.1")
            Delayed::Worker.new(:quiet => true).work_off
            site
          end
        end
        subject { site_with_versioning }
        
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
        set(:site_without_wildcard) { Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, staging.jilion.com', :dev_hostnames => "jilion.local, localhost, 127.0.0.1") }
        subject { site_without_wildcard }
        
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
        it { subject.referrer_type(nil).should == "invalid" }
      end
      
      context "with wildcard" do
        set(:site_with_wildcard) { Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, jilion.net', :dev_hostnames => "jilion.local, localhost, 127.0.0.1", :wildcard => true) }
        subject { site_with_wildcard }
        
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
        it { subject.referrer_type(nil).should == "invalid" }
      end
      
      context "with path" do
        set(:site_with_path) { Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, staging.jilion.com', :dev_hostnames => "jilion.local, localhost, 127.0.0.1", :path => "demo") }
        subject { site_with_path }
        
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
        it { subject.referrer_type(nil).should == "invalid" }
      end
      
      context "with wildcard and path" do
        set(:site_with_wildcard_and_path) { Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, jilion.net', :dev_hostnames => "jilion.local, localhost, 127.0.0.1", :path => "demo", :wildcard => true) }
        subject { site_with_wildcard_and_path }
        
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
        it { subject.referrer_type(nil).should == "invalid" }
      end
    end
  end
end




# == Schema Information
#
# Table name: sites
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  hostname        :string(255)
#  dev_hostnames   :string(255)
#  token           :string(255)
#  license         :string(255)
#  loader          :string(255)
#  state           :string(255)
#  archived_at     :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  player_mode     :string(255)     default("stable")
#  google_rank     :integer
#  alexa_rank      :integer
#  path            :string(255)
#  wildcard        :boolean
#  extra_hostnames :string(255)
#  plan_id         :integer
#  cdn_up_to_date  :boolean
#  activated_at    :datetime
#
# Indexes
#
#  index_sites_on_created_at  (created_at)
#  index_sites_on_hostname    (hostname)
#  index_sites_on_plan_id     (plan_id)
#  index_sites_on_user_id     (user_id)
#

