# coding: utf-8
require 'spec_helper'

describe Site do
  
  context "with valid attributes" do
    subject { Factory(:site) }
    
    its(:hostname)      { should =~ /jilion[0-9]+\.com/ }
    its(:dev_hostnames) { should == "localhost, 127.0.0.1" }
    its(:token)         { should =~ /^[a-z0-9]{8}$/ }
    its(:user)          { should be_present }
    its(:license)       { should_not be_present }
    its(:loader)        { should_not be_present }
    its(:player_mode)   { should == 'stable' }
    it { be_pending }
    it { be_valid }
  end
  
  describe "validations" do
    it "should validate presence of user" do
      site = Factory.build(:site, :user => nil)
      site.should_not be_valid
      site.errors[:user].should be_present
    end
    
    it "should validate presence of hostname" do
      site = Factory.build(:site, :hostname => nil)
      site.should_not be_valid
      site.hostname.should be_nil
      site.errors[:hostname].should be_present
    end
    
    # BETA
    if MySublimeVideo::Release.beta?
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
    
    describe "validate hostname" do
      %w[http://asdasd slurp .com 901.12312.123 école école.fr üpper.de].each do |host|
        it "should validate validity of hostname: #{host}" do
          site = Factory.build(:site, :hostname => host)
          site.should_not be_valid
          site.errors[:hostname].should be_present
        end
      end
      
      %w[ftp://asdasd.com asdasd.com 124.123.151.123 htp://aasds.com www.youtube.com?v=31231].each do |host|
        it "should validate non-validity of hostname: #{host}" do
          site = Factory.build(:site, :hostname => host)
          site.should be_valid
          site.errors[:hostname].should be_empty
        end
      end
    end
    
    describe "validate dev_hostnames" do
      ['123.123.123,localhost', ', ,123.123.123,'].each do |dev_hosts|
        it "should validate validity of dev_hostnames: #{dev_hosts}" do
          site = Factory.build(:site, :dev_hostnames => dev_hosts)
          site.should_not be_valid
          site.errors[:dev_hostnames].should be_present
        end
      end
      
      ['localhost', ', ,', 'localhost,, , 127.0.0.1'].each do |dev_hosts|
        it "should validate non-validity of dev_hostnames: #{dev_hosts}" do
          site = Factory.build(:site, :dev_hostnames => dev_hosts)
          site.should be_valid
          site.errors[:dev_hostnames].should be_empty
        end
      end
    end
    
    describe "validate player_mode" do
      %w[fake test foo bar].each do |player_mode|
        it "should validate inclusion of player_mode #{player_mode} in %w[dev beta stable]" do
          site = Factory.build(:site, :player_mode => player_mode)
          site.should_not be_valid
          site.errors[:player_mode].should be_present
        end
      end
      
      %w[dev beta stable].each do |player_mode|
        it "should validate inclusion of player_mode #{player_mode} in %w[dev beta stable]" do
          site = Factory.build(:site, :player_mode => player_mode)
          site.should be_valid
          site.errors[:player_mode].should be_empty
        end
      end
    end
    
    context "with already a site in db" do
      before(:each) { @site = Factory(:site) }
      
      it "should validate uniqueness of hostname by user" do
        site = Factory.build(:site, :user => @site.user, :hostname => @site.hostname)
        site.should_not be_valid
        site.errors[:hostname].should be_present
      end
      
      it "should validate uniqueness of hostname by user case-unsensitive" do
        site = Factory.build(:site, :user => @site.user, :hostname => @site.hostname.upcase)
        site.should_not be_valid
        site.errors[:hostname].should be_present
      end
      
      it "should validate uniqueness, but ignore archived sites" do
        VoxcastCDN.stub(:purge)
        @site.archive
        site = Factory.build(:site, :user => @site.user, :hostname => @site.hostname)
        site.should be_valid
        site.errors[:hostname].should_not be_present
      end
    end
    
    it "should prevent update of hostname if pending" do
      site = Factory(:site)
      site.update_attributes(:hostname => 'site.com').should be_false
      site.errors[:hostname].should be_present
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
    
    describe "dev_hostnames=" do
      it "should downcase dev_hostnames" do
        dev_host = "LOCALHOST, test;ERR, 127.]BOO[:3000, JOKE;foo"
        site = Factory.build(:site, :dev_hostnames => dev_host)
        site.dev_hostnames.should == dev_host.downcase
      end
      
      it "should clean valid dev_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory(:site, :dev_hostnames => 'http://www.localhost:3000, 127.0.0.1:3000')
        site.dev_hostnames.should == 'localhost, 127.0.0.1'
      end
      
      it "should clean invalid dev_hostnames (dev_hostnames should never contain /.+://(www.)?/)" do
        site = Factory.build(:site, :dev_hostnames => 'http://www.test;err, ftp://127.]boo[:3000, www.joke;foo')
        site.dev_hostnames.should == 'test;err, 127.]boo[:3000, joke;foo'
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
      VoxcastCDN.should_receive(:delay).twice.and_return(delay_mock)
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
        VoxcastCDN.should_receive(:delay).twice.and_return(delay_mock)
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
        VoxcastCDN.should_receive(:delay).twice.and_return(delay_mock)
        delay_mock.should_receive(:purge).with("/js/#{@site.token}.js")
        delay_mock.should_receive(:purge).with("/l/#{@site.token}.js")
        @site.archive
        @site.reload
        @site.loader.should_not be_present
        @site.license.should_not be_present
        @site.archived_at.should be_present
      end
      
    end
    
  end
  
  describe "Callbacks" do
    
    describe "before_create" do
      it "should set default dev_hostnames before create" do
        site = Factory(:site, :dev_hostnames => nil)
        site.dev_hostnames.should == 'localhost, 127.0.0.1'
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
      site = Factory(:site)
      site.template_hostnames.should == "'#{site.hostname}','localhost','127.0.0.1'"
    end
    
    it "should update ranks" do
      VCR.use_cassette('sites/ranks') do
        site = Factory(:site, :hostname => 'jilion.com')
        site.update_ranks
        site.google_rank.should == 4
        site.alexa_rank.should == 94430
      end
    end
    
    it "should set license file with template_hostnames" do
      site = Factory(:site)
      site.set_loader_and_license_file
      site.license.read.should include(site.template_hostnames)
    end
    
    it "should set loader file with token" do
      site = Factory(:site)
      site.set_loader_and_license_file
      site.loader.read.should include(site.token)
    end
    
    it "should set loader file with stable player_mode" do
      site = Factory(:site)
      site.set_loader_and_license_file
      site.loader.read.should include("http://cdn.sublimevideo.net/p/sublime.js?t=#{site.token}")
    end
    
    it "should reset hits cache" do
      VCR.use_cassette('one_saved_logs') do
        user = Factory(:user)
        site = Factory(:site, :user => user, :loader_hits_cache => 33, :player_hits_cache => 11)
        log = Factory(:log_voxcast)
        Factory(:site_usage, :site => site, :log => log, :loader_hits => 16, :player_hits => 5, :started_at => 1.minute.from_now, :ended_at => 2.minute.from_now)
        site.reset_hits_cache!(Time.now)
        site.loader_hits_cache.should == 16
        site.player_hits_cache.should == 5
      end
    end
    
    describe "referrer_type" do
      context "without wildcard or path" do
        subject { Factory(:site, :hostname => "jilion.com", :dev_hostnames => "jilion.local, localhost, 127.0.0.1") }
        
        it { subject.referrer_type("http://jilion.com").should == "main" }
        it { subject.referrer_type("http://jilion.com/test/cool").should == "main" }
        it { subject.referrer_type("https://jilion.com").should == "main" }
        it { subject.referrer_type("http://www.jilion.com").should == "main" }
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
          subject { Factory(:site, :hostname => "jilion.com", :dev_hostnames => "jilion.local, localhost, 127.0.0.1", :wildcard => true) }
          
          it { subject.referrer_type("http://blog.jilion.com").should == "main" }
          it { subject.referrer_type("http://jilion.com").should == "main" }
          it { subject.referrer_type("http://jilion.com/test/cool").should == "main" }
          it { subject.referrer_type("https://jilion.com").should == "main" }
          it { subject.referrer_type("http://www.jilion.com").should == "main" }
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
          subject { Factory(:site, :hostname => "jilion.com", :dev_hostnames => "jilion.local, localhost, 127.0.0.1", :path => "demo") }
          
          it { subject.referrer_type("http://jilion.com/demo/cool").should == "main" }
          it { subject.referrer_type("http://jilion.local").should == "dev" }
          it { subject.referrer_type("http://127.0.0.1:3000/super.html").should == "dev" }
          it { subject.referrer_type("http://localhost:3000?genial=com").should == "dev" }
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
#  alias_hostnames       :string(255)
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

