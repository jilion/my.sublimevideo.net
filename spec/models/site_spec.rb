# coding: utf-8

require 'spec_helper'

describe Site do
  
  context "with valid attributes" do
    set(:valid_site) { Factory(:site) }
    
    subject { valid_site }
    
    its(:hostname)        { should =~ /jilion[0-9]+\.com/ }
    its(:dev_hostnames)   { should == "127.0.0.1, localhost" }
    its(:extra_hostnames) { should be_nil }
    its(:path)            { should be_nil }
    its(:wildcard)        { should be_false }
    its(:token)           { should =~ /^[a-z0-9]{8}$/ }
    its(:user)            { should be_present }
    its(:license)         { should_not be_present }
    its(:loader)          { should_not be_present }
    its(:player_mode)     { should == 'stable' }
    
    it { be_pending }
    it { be_valid }
  end
  
  describe "validates" do
    it { should belong_to :user }
    
    [:hostname, :dev_hostnames].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:hostname) }
    
    context "beta release only", :release => :beta do
      it "should limit 10 sites per user" do
        user = Factory(:user)
        10.times { Factory(:site, :user => user) }
        site = Factory.build(:site, :user => user)
        site.should_not be_valid
        site.errors[:base].should be_present
      end
      it "should limit 10 active sites per user" do
        user = Factory(:user)
        10.times { Factory(:site, :user => user, :state => 'archived') }
        site = Factory.build(:site, :user => user)
        site.should be_valid
      end
    end
    
    describe "hostname" do
      %w[http://asdasd slurp .com 901.12312.123 école *.google.com *.com jilion.local].each do |host|
        it "should not allow: #{host}" do
          site = Factory.build(:site, :hostname => host)
          site.should_not be_valid
          site.errors[:hostname].should be_present
        end
      end
      
      %w[ftp://asdasd.com asdasd.com école.fr 124.123.151.123 üpper.de htp://aasds.com www.youtube.com?v=31231].each do |host|
        it "should allow: #{host}" do
          site = Factory.build(:site, :hostname => host)
          site.should be_valid
          site.errors[:hostname].should be_empty
        end
      end
    end
    
    describe "extra_hostnames" do
      ["*.jilion.com", 'localhost, jilion.net', 'jilion.local', 'jilion.dev, jilion.net', 'jilion.com'].each do |extra_hosts|
        it "should not allow: #{extra_hosts}" do
          site = Factory.build(:site, :hostname => 'jilion.com', :extra_hostnames => extra_hosts)
          site.should_not be_valid
          site.errors[:extra_hostnames].should be_present
        end
      end
      
      ['jilion.net', 'jilion.org, jilion.fr', 'jilion.org, 124.123.123.123', nil, ', ,', '127.0.0.1'].each do |extra_hosts|
        it "should allow: #{extra_hosts}" do
          site = Factory.build(:site, :hostname => 'jilion.com', :extra_hostnames => extra_hosts)
          site.should be_valid
          site.errors[:extra_hostnames].should be_empty
        end
      end
    end
    
    describe "dev_hostnames" do
      ["*.google.local", 'staging.google.com', 'google.com', 'localhost, localhost'].each do |dev_hosts|
        it "should not allow: #{dev_hosts}" do
          site = Factory.build(:site, :hostname => 'jilion.com', :dev_hostnames => dev_hosts)
          site.should_not be_valid
          site.errors[:dev_hostnames].should be_present
        end
      end
      
      ['123.123.123,localhost', 'google.local', ', ,123.123.123,', 'localhost', ', ,', 'localhost,, , 127.0.0.1'].each do |dev_hosts|
        it "should allow: #{dev_hosts}" do
          site = Factory.build(:site, :dev_hostnames => dev_hosts)
          site.should be_valid
          site.errors[:dev_hostnames].should be_empty
        end
      end
    end
    
    describe "validate player_mode" do
      %w[fake test].each do |player_mode|
        it "should not allow: #{player_mode}" do
          site = Factory.build(:site, :player_mode => player_mode)
          site.should_not be_valid
          site.errors[:player_mode].should be_present
        end
      end
      
      %w[dev beta stable].each do |player_mode|
        it "should allow: #{player_mode}" do
          site = Factory.build(:site, :player_mode => player_mode)
          site.should be_valid
          site.errors[:player_mode].should be_empty
        end
      end
    end
    
    context "with already a site in db" do
      set(:existing_site) { Factory(:site) }
      
      it "should validate uniqueness of hostname by user" do
        site = Factory.build(:site, :user => existing_site.user, :hostname => existing_site.hostname)
        site.should_not be_valid
        site.errors[:hostname].should be_present
      end
      
      it "should validate uniqueness of hostname by user case-unsensitive" do
        site = Factory.build(:site, :user => existing_site.user, :hostname => existing_site.hostname.upcase)
        site.should_not be_valid
        site.errors[:hostname].should be_present
      end
      
      it "should validate uniqueness, but ignore archived sites" do
        VoxcastCDN.stub(:purge)
        existing_site.archive
        site = Factory.build(:site, :user => existing_site.user, :hostname => existing_site.hostname)
        site.should be_valid
        site.errors[:hostname].should_not be_present
      end
      
      it "should validate uniqueness even on update" do
        VoxcastCDN.stub(:purge)
        site = Factory(:site, :user => existing_site.user)
        site.activate
        site = Site.find(site.id)
        site.hostname = existing_site.hostname
        site.should_not be_valid
        site.errors[:hostname].should be_present
      end
    end
    
    it "should prevent update of hostname when not active" do
      site = Factory(:site, :hostname => 'jilion.com')
      site.update_attributes(:hostname => 'site.com')
      site.reload.hostname.should == 'jilion.com'
    end
    it "should be able to update hostname even when active" do
      site = Factory(:site, :hostname => 'jilion.com')
      site.activate
      site.update_attributes(:hostname => 'site.com')
      site.reload.hostname.should == 'site.com'
    end
    
    it "should prevent update of dev_hostnames if pending" do
      site = Factory(:site)
      site.update_attributes(:dev_hostnames => 'site.local').should be_false
      site.errors[:dev_hostnames].should be_present
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
      
      it "should clean valid hostname (hostname should never contain /.+://(www.)?/)" do
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
        site = Factory(:site, :extra_hostnames => 'http://www.jime.org:3000, 127.0.0.1:3000')
        site.extra_hostnames.should == 'jime.org, 127.0.0.1'
      end
    end
    
    describe "dev_hostnames=" do
      it "should downcase dev_hostnames" do
        dev_host = "LOCALHOST, test;ERR, 127.]BOO[, JOKE;foo"
        site = Factory.build(:site, :dev_hostnames => dev_host)
        site.dev_hostnames.should == dev_host.downcase
      end
      
      it "should clean valid dev_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory(:site, :dev_hostnames => 'http://www.localhost:3000, 127.0.0.1:3000')
        site.dev_hostnames.should == 'localhost, 127.0.0.1'
      end
      
      it "should clean invalid dev_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory.build(:site, :dev_hostnames => 'http://www.test;err, ftp://127.]boo[:3000, www.joke;foo')
        site.dev_hostnames.should == 'test;err, 127.]boo[, joke;foo'
      end
    end
  end
  
  describe "State Machine" do
    it "activate should set license file" do
      site = Factory(:site)
      site.activate
      site.license.should be_present
    end
    
    it "activate should set loader file" do
      site = Factory(:site)
      site.activate
      site.loader.should be_present
    end
    
    it "first activate should not purge license file" do
      site = Factory(:site)
      VoxcastCDN.should_not_receive(:purge).with("/l/#{site.token}.js")
      site.activate
    end
    
    it "first activate should not purge loader file" do
      site = Factory(:site)
      VoxcastCDN.should_not_receive(:purge).with("/js/#{site.token}.js")
      site.activate
    end
    
    it "activate on an already active site should purge loader & license file" do
      site = Factory(:site)
      site.activate
      delay_mock = mock('Delay')
      VoxcastCDN.should_receive(:delay).twice { delay_mock }
      delay_mock.should_receive(:purge).with("/js/#{site.token}.js")
      delay_mock.should_receive(:purge).with("/l/#{site.token}.js")
      site.activate
    end
    
    context "with a site activated" do
      before(:each) do
        @site = Factory(:site)
        @site.activate
      end
      
      it "should clear & purge license & loader when suspend" do
        delay_mock = mock('Delay')
        VoxcastCDN.should_receive(:delay).twice { delay_mock }
        delay_mock.should_receive(:purge).with("/js/#{@site.token}.js")
        delay_mock.should_receive(:purge).with("/l/#{@site.token}.js")
        @site.suspend
        @site = Site.find(@site)
        @site.loader.should_not be_present
        @site.license.should_not be_present
      end
      
      it "should reset license & loader when unsuspend" do
        VoxcastCDN.stub(:purge)
        @site.suspend
        @site = Site.find(@site)
        @site.unsuspend
        @site.loader.should be_present
        @site.license.should be_present
      end
      
      it "should clear & purge license & loader and set archived_at when archive" do
        delay_mock = mock('Delay')
        VoxcastCDN.should_receive(:delay).twice { delay_mock }
        delay_mock.should_receive(:purge).with("/js/#{@site.token}.js")
        delay_mock.should_receive(:purge).with("/l/#{@site.token}.js")
        @site.archive
        @site.reload
        @site.loader.should_not be_present
        @site.license.should_not be_present
        @site.archived_at.should be_present
      end
      
      if MySublimeVideo::Release.public?
        it "should be able to set path" do
          @site.update_attributes(:path => '/users/thibaud')
          @site.path.should == 'users/thibaud'
        end
        
        it "should be able to set wildcard" do
          @site.update_attributes(:wildcard => "1")
          @site.wildcard.should be_true
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
    
    describe "before_create" do
      it "should set default dev_hostnames if not set" do
        site = Factory(:site, :dev_hostnames => nil)
        site.dev_hostnames.should == '127.0.0.1, localhost'
      end
      
      it "should not set 127.0.0.1 dev_hostnames by default before create if main domain is 127.0.0.1" do
        site = Factory(:site, :hostname => '127.0.0.1', :dev_hostnames => nil)
        site.dev_hostnames.should == 'localhost'
      end
    end
    
    describe "after_create" do
      it "should delay update_ranks" do
        lambda { Factory(:site) }.should change(Delayed::Job.where(:handler.matches => "%update_ranks%"), :count).by(1)
      end
    end
  end
  
  describe "Instance Methods" do
    
    it "should return good template_hostnames" do
      site = Factory(:site, :extra_hostnames => "jilion.net, jilion.org")
      site.template_hostnames.should == "'#{site.hostname}','jilion.net','jilion.org','127.0.0.1','localhost'"
    end
    
    it "should update ranks" do
      VCR.use_cassette('sites/ranks') do
        site = Factory(:site, :hostname => 'jilion.com')
        site.update_ranks
        site.google_rank.should == 4
        site.alexa_rank.should == 94430
      end
    end
    
    describe "#update_ranks" do
      it "should update ranks" do
        VCR.use_cassette('sites/ranks') do
          site = Factory(:site, :hostname => 'jilion.com')
          site.update_ranks
          site.google_rank.should == 4
          site.alexa_rank.should == 94430
        end
      end
    end
    
    describe "#set_loader_and_license_file" do
      set(:site_with_set_loader_and_license_file) { Factory(:site).tap { |s| s.set_loader_and_license_file } }
      
      it "should set license file with template_hostnames" do
        site_with_set_loader_and_license_file.license.read.should include(site_with_set_loader_and_license_file.template_hostnames)
      end
      
      it "should set loader file with token" do
        site_with_set_loader_and_license_file.loader.read.should include(site_with_set_loader_and_license_file.token)
      end
      
      it "should set loader file with stable player_mode" do
        site_with_set_loader_and_license_file.loader.read.should include("http://cdn.sublimevideo.net/p/sublime.js?t=#{site_with_set_loader_and_license_file.token}")
      end
    end
    
    describe "#reset_hits_cache!" do
      it "should reset hits cache" do
        VCR.use_cassette('one_saved_logs') do
          user = Factory(:user)
          site = Factory(:site, :user => user, :loader_hits_cache => 33, :player_hits_cache => 11)
          log = Factory(:log_voxcast)
          Factory(:site_usage, :site_id => site.id, :day => Time.now.beginning_of_day, :loader_hits => 16, :player_hits => 5)
          site.reset_hits_cache!(1.day.ago)
          site.loader_hits_cache.should == 16
          site.player_hits_cache.should == 5
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
        subject do
          with_versioning do
            Timecop.travel(1.day.ago)
            site = Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, jilion.net', :dev_hostnames => "localhost, 127.0.0.1")
            site.activate
            Timecop.return
            site.update_attributes(:hostname => "jilion.net", :extra_hostnames => 'jilion.org, jilion.com', :dev_hostnames => "jilion.local, localhost, 127.0.0.1")
            site
          end
        end
        
        it { subject.referrer_type("http://jilion.co.uk").should == "invalid" }
        it { subject.referrer_type("http://jilion.com").should == "extra" }
        it { subject.referrer_type("http://jilion.org").should == "extra" }
        it { subject.referrer_type("http://jilion.net").should == "main" }
        it { subject.referrer_type("http://jilion.local").should == "dev" }
        it { subject.referrer_type("http://jilion.com", 1.day.ago).should == "main" }
        it { subject.referrer_type("http://jilion.org", 1.day.ago).should == "extra" }
        it { subject.referrer_type("http://jilion.net", 1.day.ago).should == "extra" }
        it { subject.referrer_type("http://jilion.co.uk", 1.day.ago).should == "invalid" }
        it { subject.referrer_type("http://jilion.local", 1.day.ago).should == "invalid" }
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
      
      if MySublimeVideo::Release.public?
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
          it { subject.referrer_type("http://127.0.0.1:3000/super.html").should == "dev" }
          it { subject.referrer_type("http://localhost:3000?genial=com").should == "dev" }
          it { subject.referrer_type("http://google.com").should == "invalid" }
          it { subject.referrer_type("google.com").should == "invalid" }
          it { subject.referrer_type("jilion.com").should == "invalid" }
          it { subject.referrer_type("-").should == "invalid" }
          it { subject.referrer_type(nil).should == "invalid" }
        end
        context "with path" do
          set(:site_with_path) { Factory(:site, :hostname => "jilion.com", :extra_hostnames => 'jilion.org, staging.jilion.com', :dev_hostnames => "jilion.local, localhost, 127.0.0.1", :path => "demo") }
          subject { site_with_path }
          
          it { subject.referrer_type("http://staging.jilion.com").should == "main" }
          it { subject.referrer_type("http://jilion.org").should == "extra" }
          it { subject.referrer_type("http://jilion.com/demo/cool").should == "main" }
          it { subject.referrer_type("http://127.0.0.1:3000/demo/super.html").should == "dev" }
          it { subject.referrer_type("http://localhost:3000/demo?genial=com").should == "dev" }
          it { subject.referrer_type("http://localhost:3000?genial=com").should == "invalid" }
          it { subject.referrer_type("http://jilion.local").should == "invalid" }
          it { subject.referrer_type("http://jilion.com/test/cool").should == "invalid" }
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
  
  describe "Special Methods" do
    describe ".update_hostnames" do
      before(:all) do
        @not_public_hostname     = Factory.build(:site, :hostname => 'jilion.local').tap { |s| s.save(:validate => false) }
        @not_local_dev_hostname1 = Factory.build(:site, :hostname => 'jilion.com', :dev_hostnames => 'localhost, jilion.net').tap { |s| s.save(:validate => false) }
        @not_local_dev_hostname2 = Factory.build(:site, :hostname => 'jilion.com', :dev_hostnames => 'jilion.net, jilion.org').tap { |s| s.save(:validate => false) }
        @duplicated_dev_hostname1 = Factory.build(:site, :hostname => '127.0.0.1', :dev_hostnames => 'localhost, 127.0.0.1').tap { |s| s.save(:validate => false) }
        @duplicated_dev_hostname2 = Factory.build(:site, :hostname => 'jilion.com', :dev_hostnames => 'localhost, 127.0.0.1, 127.0.0.1').tap { |s| s.save(:validate => false) }
        @mixed_invalid_site      = Factory.build(:site, :hostname => 'jilion.local', :dev_hostnames => 'localhost, jilion.local, 127.0.0.1, jilion.net').tap { |s| s.save(:validate => false) }
      end
      
      it "all sites created should be invalid" do
        [@not_public_hostname, @not_local_dev_hostname1, @not_local_dev_hostname2, @duplicated_dev_hostname1, @duplicated_dev_hostname2, @mixed_invalid_site].each do |invalid_site|
          invalid_site.should_not be_valid
        end
      end
      
      context "actually test the method" do
        before(:all) do
          Delayed::Job.delete_all
          described_class.update_hostnames
        end
        
        it "should have delayed 3 site activations" do
          Delayed::Job.count.should == 4
          Delayed::Job.last.name.should == 'Site#activate'
        end
        
        it "should not modify site when hostname is invalid" do
          @not_public_hostname.reload.hostname.should == 'jilion.local'
          @not_public_hostname.dev_hostnames.should   == '127.0.0.1, localhost'
          @not_public_hostname.extra_hostnames.should == nil
        end
        
        it "should move dev hostnames that belong to extra hostnames" do
          @not_local_dev_hostname1.reload.hostname.should == 'jilion.com'
          @not_local_dev_hostname1.dev_hostnames.should   == 'localhost'
          @not_local_dev_hostname1.extra_hostnames.should == 'jilion.net'
        end
        
        it "should move dev hostnames that belong to extra hostnames (bis)" do
          @not_local_dev_hostname2.reload.hostname.should == 'jilion.com'
          @not_local_dev_hostname2.dev_hostnames.should   == ''
          @not_local_dev_hostname2.extra_hostnames.should == 'jilion.org, jilion.net'
        end
        
        it "should remove duplicate dev domain" do
          @duplicated_dev_hostname1.reload.hostname.should == '127.0.0.1'
          @duplicated_dev_hostname1.dev_hostnames.should   == 'localhost'
          @duplicated_dev_hostname1.extra_hostnames.should == nil
        end
        
        it "should remove duplicate dev domain (bis)" do
          @duplicated_dev_hostname2.reload.hostname.should == 'jilion.com'
          @duplicated_dev_hostname2.dev_hostnames.should   == '127.0.0.1, localhost'
          @duplicated_dev_hostname2.extra_hostnames.should == nil
        end
        
        it "should not modify hostname when hostname is invalid, move dev hostnames that belong to extra hostnames, remove duplicate dev domain" do
          @mixed_invalid_site.reload.hostname.should == 'jilion.local'
          @mixed_invalid_site.dev_hostnames.should   == '127.0.0.1, localhost'
          @mixed_invalid_site.extra_hostnames.should == 'jilion.net'
        end
        
        it "3 sites are now valid, 2 are still invalid" do
          [@not_public_hostname, @mixed_invalid_site].each do |invalid_site|
            invalid_site.should_not be_valid
          end
          
          [@not_local_dev_hostname1, @not_local_dev_hostname2, @duplicated_dev_hostname1, @duplicated_dev_hostname2].each do |valid_site|
            valid_site.should be_valid
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
#  id                    :integer         not null, primary key
#  user_id               :integer
#  hostname              :string(255)
#  dev_hostnames         :string(255)
#  token                 :string(255)
#  license               :string(255)
#  loader                :string(255)
#  state                 :string(255)
#  loader_hits_cache     :integer(8)      default(0)
#  player_hits_cache     :integer(8)      default(0)
#  flash_hits_cache      :integer(8)      default(0)
#  archived_at           :datetime
#  created_at            :datetime
#  updated_at            :datetime
#  player_mode           :string(255)     default("stable")
#  requests_s3_cache     :integer(8)      default(0)
#  traffic_s3_cache      :integer(8)      default(0)
#  traffic_voxcast_cache :integer(8)      default(0)
#  google_rank           :integer
#  alexa_rank            :integer
#  path                  :string(255)
#  wildcard              :boolean
#
# Indexes
#
#  index_sites_on_created_at                     (created_at)
#  index_sites_on_hostname                       (hostname)
#  index_sites_on_player_hits_cache_and_user_id  (player_hits_cache,user_id)
#  index_sites_on_user_id                        (user_id)
#

