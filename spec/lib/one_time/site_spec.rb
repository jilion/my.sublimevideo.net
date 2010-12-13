# coding: utf-8
require 'spec_helper'

describe OneTime::Site do
  before(:all) do
    @zeno = Factory(:user, :email => "zeno@jilion.com")
    @remy = Factory(:user, :email => "remy@jilion.com")
  end
  
  describe ".update_hostnames" do
    context "on all sites" do
      before(:all) do
        @not_public_hostname      = Factory.build(:site, :hostname => 'jilion.local').tap { |s| s.save(:validate => false) }
        @not_local_dev_hostname1  = Factory.build(:site, :hostname => 'jilion.com', :dev_hostnames => 'localhost, jilion.net').tap { |s| s.save(:validate => false) }
        @not_local_dev_hostname2  = Factory.build(:site, :hostname => 'jilion.com', :dev_hostnames => 'jilion.net, jilion.org').tap { |s| s.save(:validate => false) }
        @duplicated_dev_hostname1 = Factory.build(:site, :hostname => '127.0.0.1', :dev_hostnames => 'localhost, 127.0.0.1').tap { |s| s.save(:validate => false) }
        @duplicated_dev_hostname2 = Factory.build(:site, :hostname => 'jilion.com', :dev_hostnames => 'localhost, 127.0.0.1, 127.0.0.1, localhost').tap { |s| s.save(:validate => false) }
        @mixed_invalid_site       = Factory.build(:site, :hostname => 'jilion.local', :dev_hostnames => 'localhost, jilion.local, 127.0.0.1, jilion.net').tap { |s| s.save(:validate => false) }
      end
      
      it "all sites created should be invalid" do
        [@not_public_hostname, @not_local_dev_hostname1, @not_local_dev_hostname2, @duplicated_dev_hostname1, @duplicated_dev_hostname2, @mixed_invalid_site].each do |invalid_site|
          invalid_site.should_not be_valid
        end
      end
      
      context "actually test the method" do
        before(:all) { described_class.update_hostnames(false) }
        
        it "should not modify site when hostname is invalid" do
          @not_public_hostname.reload.hostname.should == nil
          @not_public_hostname.dev_hostnames.should   == 'jilion.local, localhost'
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
          @not_local_dev_hostname2.extra_hostnames.should == 'jilion.net, jilion.org'
        end
        
        it "should remove duplicate dev domain" do
          @duplicated_dev_hostname1.reload.hostname.should == nil
          @duplicated_dev_hostname1.dev_hostnames.should   == '127.0.0.1, localhost'
          @duplicated_dev_hostname1.extra_hostnames.should == nil
        end
        
        it "should remove duplicate dev domain (bis)" do
          @duplicated_dev_hostname2.reload.hostname.should == 'jilion.com'
          @duplicated_dev_hostname2.dev_hostnames.should   == '127.0.0.1, localhost'
          @duplicated_dev_hostname2.extra_hostnames.should == nil
        end
        
        it "should not remove hostname when hostname is invalid and move it to dev, move dev hostnames that belong to extra hostnames, remove duplicate dev domain" do
          @mixed_invalid_site.reload.hostname.should == nil
          @mixed_invalid_site.dev_hostnames.should   == '127.0.0.1, jilion.local, localhost'
          @mixed_invalid_site.extra_hostnames.should == 'jilion.net'
        end
        
        it "all sites should be valid" do
          [@not_public_hostname.reload, @not_local_dev_hostname1.reload, @not_local_dev_hostname2.reload, @duplicated_dev_hostname1.reload, @duplicated_dev_hostname2.reload, @mixed_invalid_site.reload].each do |valid_site|
            valid_site.should be_valid
          end
        end
      end
      
    end
    
    context "only staff sites" do
      before(:all) do
        @not_public_hostname     = Factory.build(:site, :user => @zeno, :hostname => 'jilion.local').tap { |s| s.save(:validate => false) }
        @not_local_dev_hostname1 = Factory.build(:site, :user => @remy, :hostname => 'jilion.com', :dev_hostnames => 'localhost, jilion.net').tap { |s| s.save(:validate => false) }
        @not_local_dev_hostname2 = Factory.build(:site, :hostname => 'jilion.com', :dev_hostnames => 'jilion.net, jilion.org').tap { |s| s.save(:validate => false) }
      end
      
      it "all sites created should be invalid" do
        [@not_public_hostname, @not_local_dev_hostname1, @not_local_dev_hostname2].each do |invalid_site|
          invalid_site.should_not be_valid
        end
      end
      
      context "actually test the method" do
        before(:all) { described_class.update_hostnames(true) }
        
        it "should not modify site when hostname is invalid" do
          @not_public_hostname.reload.hostname.should == nil
          @not_public_hostname.dev_hostnames.should   == 'jilion.local, localhost'
          @not_public_hostname.extra_hostnames.should == nil
        end
        
        it "should move dev hostnames that belong to extra hostnames" do
          @not_local_dev_hostname1.reload.hostname.should == 'jilion.com'
          @not_local_dev_hostname1.dev_hostnames.should   == 'localhost'
          @not_local_dev_hostname1.extra_hostnames.should == 'jilion.net'
        end
        
        it "should not change site that don't belong to staff" do
          @not_local_dev_hostname2.reload.hostname.should == 'jilion.com'
          @not_local_dev_hostname2.dev_hostnames.should   == 'jilion.net, jilion.org'
          @not_local_dev_hostname2.extra_hostnames.should == nil
        end
        
        it "all staff sites should be valid" do
          [@not_public_hostname.reload, @not_local_dev_hostname1.reload].each do |valid_site|
            valid_site.should be_valid
          end
        end
        
        it "should let other sites as they were before" do
          @not_local_dev_hostname2.reload.should_not be_valid
        end
      end
    end
    
  end
  
  describe ".set_beta_state" do
    before(:all) do
      @staff_site_1 = Factory(:site, :user => @zeno)
      @staff_site_2 = Factory(:site, :user => @remy)
      @other_site_1 = Factory(:site)
      @other_site_2 = Factory(:site)
    end
    
    it "all sites created should be dev" do
      [@staff_site_1, @staff_site_2, @other_site_1, @other_site_2].each do |site|
        site.should be_dev
      end
    end
    
    context "actually test the method for staff sites only" do
      before(:all) { described_class.set_beta_state(true) }
      
      it "should set staff sites to beta" do
        [@staff_site_1.reload, @staff_site_2.reload].each do |site|
          site.should be_beta
        end
      end
      
      it "let the other as they were before" do
        [@other_site_1.reload, @other_site_2.reload].each do |site|
          site.should be_dev
        end
      end
    end
    
    context "actually test the method for all sites" do
      before(:all) { described_class.set_beta_state(false) }
      
      it "should set all sites to beta" do
        [@staff_site_1.reload, @staff_site_2.reload, @other_site_1.reload, @other_site_2.reload].each do |site|
          site.should be_beta
        end
      end
    end
  end
  
end