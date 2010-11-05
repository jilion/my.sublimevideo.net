# coding: utf-8
require 'spec_helper'

describe Site do
  context "with valid attributes" do
    subject { Factory(:site) }
    
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
    its(:player_mode)     { should == 'stable' }
    
    it { be_pending }
    it { be_valid }
  end
  
  describe "validates" do
    subject { Factory(:site) }
    
    it { should belong_to :user }
    it { should belong_to :plan }
    it { should have_many :invoice_items }
    it { should have_many(:invoices).through(:invoice_items) }
    it { should have_and_belong_to_many :addons }
    
    [:hostname, :dev_hostnames].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:plan).with_message("Please choose a plan") }
    
    it { should allow_value('dev').for(:player_mode) }
    it { should allow_value('beta').for(:player_mode) }
    it { should allow_value('stable').for(:player_mode) }
    it { should_not allow_value('fake').for(:player_mode) }
    
    describe "user credit card" do
      it "should be validate" do
        site = Factory.build(:site, :user_attributes => { :cc_full_name => "Bob", :cc_expire_on => 1.year.from_now } )
        site.should_not be_valid
        site.user.errors[:cc_number].should be_present
        site.user.errors[:cc_type].should be_present
        site.user.errors[:cc_verification_value].should be_present
      end
    end
    
    describe "hostname" do
      it "should not be required until activation" do
        site = Factory.build(:site, :hostname => nil)
        site.should be_valid
        site.errors[:hostname].should be_empty
      end
      
      it "should be required on activation" do
        site = Factory(:site, :hostname => nil)
        site.should be_valid
        site.activate.should be_false
        site.errors[:hostname].should be_present
      end
      
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
      ["*.jilion.com", 'localhost, jilion.net', 'jilion.local', 'jilion.dev, jilion.net', 'jilion.com', '127.0.0.1'].each do |extra_hosts|
        it "should not allow: #{extra_hosts}" do
          site = Factory.build(:site, :hostname => 'jilion.com', :extra_hostnames => extra_hosts)
          site.should_not be_valid
          site.errors[:extra_hostnames].should be_present
        end
      end
      
      ['jilion.net', 'jilion.org, jilion.fr', 'jilion.org, 124.123.123.123', nil, ', ,'].each do |extra_hosts|
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
    
    describe "no hostnames at all" do
      it "should require at least one of hostname, dev, or extra domains on creation" do
        site = Factory.build(:site, :hostname => '', :extra_hostnames => '', :dev_hostnames => '')
        site.should_not be_valid
        site.errors[:base].should == ["Please set at least a development or an extra domain"]
      end
      
      it "should not add an error on base because an error is already added on hostname when blank and site is active" do
        site = Factory(:site, :hostname => "test.com").tap { |s| s.activate }
        site.hostname = nil
        site.dev_hostnames = nil
        site.should_not be_valid
        site.errors[:base].should == []
      end
    end
    
    context "with already a site in db" do
      set(:existing_site) { Factory(:site) }
      
      it "should validate uniqueness of hostname by user" do
        site = Factory.build(:site, :user => existing_site.user, :hostname => existing_site.hostname)
        site.should_not be_valid
        site.errors[:hostname].should == ["You have already registered this domain"]
      end
      
      it "should validate uniqueness of hostname by user case-unsensitive" do
        site = Factory.build(:site, :user => existing_site.user, :hostname => existing_site.hostname.upcase)
        site.should_not be_valid
        site.errors[:hostname].should == ["You have already registered this domain"]
      end
      
      it "should validate uniqueness, but ignore archived sites" do
        VoxcastCDN.stub(:purge)
        existing_site.archive
        site = Factory.build(:site, :user => existing_site.user, :hostname => existing_site.hostname)
        site.should be_valid
        site.errors[:hostname].should be_empty
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
    
    it "should be able to update hostname even when active" do
      site = Factory(:site, :hostname => 'jilion.com')
      site.activate
      site.update_attributes(:hostname => 'site.com')
      site.reload.hostname.should == 'site.com'
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
    
    describe "#path=" do
      it "should remove first /" do
        site = Factory(:site, :path => '/users/thibaud')
        site.path.should == 'users/thibaud'
      end
    end
  end
  
  describe "State Machine" do
    describe "#activate" do
      let(:site) { Factory(:site) }
      
      it "activate should set license file" do
        site.activate
        site.license.should be_present
      end
      
      it "activate should set loader file" do
        site.activate
        site.loader.should be_present
      end
      
      it "first activate should not purge license file" do
        VoxcastCDN.should_not_receive(:purge).with("/l/#{site.token}.js")
        site.activate
      end
      
      it "first activate should not purge loader file" do
        VoxcastCDN.should_not_receive(:purge).with("/js/#{site.token}.js")
        site.activate
      end
      
      it "activate on an already active site should purge loader & license file" do
        site.activate
        delay_mock = mock('Delay')
        VoxcastCDN.should_receive(:delay).twice { delay_mock }
        delay_mock.should_receive(:purge).with("/js/#{site.token}.js")
        delay_mock.should_receive(:purge).with("/l/#{site.token}.js")
        site.activate
      end
    end
    
    context "with a site activated" do
      subject { Factory(:site).tap { |s| s.activate } }
      
      describe "#suspend" do
        it "should clear & purge license & loader when suspend" do
          subject.activate
          delay_mock = mock('Delay')
          VoxcastCDN.should_receive(:delay).twice { delay_mock }
          delay_mock.should_receive(:purge).with("/js/#{subject.token}.js")
          delay_mock.should_receive(:purge).with("/l/#{subject.token}.js")
          subject.suspend
          site = Site.find(subject.id)
          site.reload.loader.should_not be_present
          site.license.should_not be_present
        end
      end
      
      describe "#unsuspend" do
        it "should reset license & loader when unsuspend" do
          subject.activate
          VoxcastCDN.stub(:purge)
          subject.suspend
          site = Site.find(subject.id)
          site.unsuspend
          site.reload.loader.should be_present
          site.license.should be_present
        end
      end
      
      describe "#archive" do
        it "should clear & purge license & loader and set archived_at when archive" do
          subject.activate
          delay_mock = mock('Delay')
          VoxcastCDN.should_receive(:delay).twice { delay_mock }
          delay_mock.should_receive(:purge).with("/js/#{subject.token}.js")
          delay_mock.should_receive(:purge).with("/l/#{subject.token}.js")
          subject.archive
          subject.reload
          subject.loader.should_not be_present
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
    
    describe "after_create" do
      it "should delay update_ranks" do
        lambda { Factory(:site) }.should change(Delayed::Job.where(:handler.matches => "%update_ranks%"), :count).by(1)
      end
    end
  end
  
  describe "Instance Methods" do
    describe "#template_hostnames" do
      it "should return good template_hostnames" do
        site = Factory(:site, :extra_hostnames => "jilion.net, jilion.org", :dev_hostnames => '127.0.0.1,localhost')
        site.template_hostnames.should == "'#{site.hostname}','jilion.net','jilion.org','127.0.0.1','localhost'"
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

