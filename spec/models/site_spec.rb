# == Schema Information
#
# Table name: sites
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  hostname      :string(255)
#  dev_hostnames :string(255)
#  token         :string(255)
#  licence       :string(255)
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
    it { subject.token.should           =~ /^[a-zA-Z0-9]{8}$/     }
    it { subject.licenses_hashes.should == "'3fdf11619e7e6146833fdb6c3b0b2c147cf704c4','b9271d7e78549de385697cbb549069c86093ff4c','adbd136715d0a7480af82cc4c8e9cc80690aa420'" }
    it { subject.licence.url.should be_nil }
    it { subject.user.should be_present }
    it { subject.should be_pending }
    it { subject.should be_valid }
  end
  
  describe "validates" do
    it "should validate presence of user" do
      site = Factory.build(:site, :user => nil)
      site.should_not be_valid
      site.errors[:user].should be_present
    end
    it "should validate presence of hostname" do
      site = Factory.build(:site, :hostname => nil)
      site.should_not be_valid
      site.errors[:hostname].should be_present
    end
    
    %w[http://asdasd slurp .com 901.12312.123 école école.fr üpper.de].each do |host|
      it "should validate validity of hostname: #{host}" do
        site = Factory.build(:site, :hostname => host)
        site.should_not be_valid
        site.errors[:hostname].should be_present
      end
    end
    %w[ftp://asdasd.com asdasd.com 124.123.151.123 htp://aasds.com].each do |host|
      it "should validate validity of hostname: #{host}" do
        site = Factory.build(:site, :hostname => host)
        site.should be_valid
        site.errors[:hostname].should_not be_present
      end
    end
    ['123.123.123,localhost', ', ,123.123.123,'].each do |hosts|
      it "should validate validity of hostname: #{hosts}" do
        site = Factory.build(:site, :dev_hostnames => hosts)
        site.should_not be_valid
        site.errors[:dev_hostnames].should be_present
      end
    end
    ['localhost', ', ,', 'localhost,, ,'].each do |hosts|
      it "should validate validity of hostname: #{hosts}" do
        site = Factory.build(:site, :dev_hostnames => hosts)
        site.should be_valid
        site.errors[:dev_hostnames].should_not be_present
      end
    end
    
    it "should validate hostname even without http://" do
      site = Factory(:site, :hostname => 'www.youtube.com?video=31231')
      site.hostname.should == 'youtube.com'
    end
    it "should validate & clean hostname" do
      site = Factory(:site, :hostname => 'http://www.youtube.com?video=31231')
      site.hostname.should == 'youtube.com'
    end
    it "should validate & clean dev_hostnames" do
      site = Factory(:site, :dev_hostnames => 'http://www.localhost:3000, 127.0.0.1:3000')
      site.dev_hostnames.should == 'localhost, 127.0.0.1'
    end
    
    context "with already a site in db" do
      before(:each) { @site = Factory(:site) }
      
      it "should validate uniqueness of hostname by user" do
        site = Factory.build(:site, :user => @site.user, :hostname => @site.hostname)
        site.should_not be_valid
        site.errors[:hostname].should be_present
      end
    end
  end
  
  describe "State Machine" do
    
    it "activate should set licence file" do
      site = Factory(:site)
      site.activate
      site.licence.url.should be_present
    end
    
  end
  
  describe "Callbacks" do
    
    it "should set default dev_hostnames before create" do
      site = Factory(:site, :dev_hostnames => nil)
      site.dev_hostnames.should == 'localhost, 127.0.0.1'
    end
    
  end
  
  describe "Instance Methods" do
    
    it "should set licence file with licenses_hashes" do
      site = Factory(:site)
      site.set_licence_file
      site.licence.read.should include(site.licenses_hashes)
    end
    
  end
  
end