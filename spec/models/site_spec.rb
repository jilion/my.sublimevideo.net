# == Schema Information
#
# Table name: sites
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  hostname      :string(255)
#  dev_hostnames :string(255)
#  token         :string(255)
#  license       :string(255)
#  state         :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe Site do
  
  context "with valid attributes" do
    subject { Factory(:site) }
    
    it { subject.hostname.should        == "youtube.com"          }
    it { subject.dev_hostnames.should   == "localhost, 127.0.0.1" }
    it { subject.token.should           =~ /^[a-z0-9]{8}$/     }
    it { subject.licenses_hashes.should == "'3fdf11619e7e6146833fdb6c3b0b2c147cf704c4','b9271d7e78549de385697cbb549069c86093ff4c','adbd136715d0a7480af82cc4c8e9cc80690aa420'" }
    it { subject.license.url.should be_nil }
    it { subject.user.should be_present }
    it { subject.should be_pending }
    it { subject.should be_valid }
  end
  
  describe "Validations" do
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
    
    describe "validate hostname" do
      %w[http://asdasd slurp .com 901.12312.123 école école.fr üpper.de].each do |host|
        it "should validate validity of hostname: #{host}" do
          site = Factory.build(:site, :hostname => host)
          site.should_not be_valid
          site.errors[:hostname].should be_present
        end
      end
      
      %w[ftp://asdasd.com asdasd.com 124.123.151.123 htp://aasds.com www.youtube.com?video=31231].each do |host|
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
        site = Factory(:site, :hostname => 'http://www.youtube.com?video=31231')
        site.hostname.should == 'youtube.com'
      end
      
      %w[http://www.youtube.com?video=31231 www.youtube.com?video=31231 youtube.com?video=31231].each do |host|
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
      site.license.url.should be_present
    end
  end
  
  describe "Callbacks" do
    describe "before_create" do
      it "should set default dev_hostnames before create" do
        site = Factory(:site, :dev_hostnames => nil)
        site.dev_hostnames.should == 'localhost, 127.0.0.1'
      end
    end
  end
  
  describe "Instance Methods" do
    
    it "should set license file with licenses_hashes" do
      site = Factory(:site)
      site.set_license_file
      site.license.read.should include(site.licenses_hashes)
    end
    
  end
  
end