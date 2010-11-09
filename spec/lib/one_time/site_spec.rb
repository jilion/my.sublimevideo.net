# coding: utf-8
require 'spec_helper'

describe OneTime::Site do
  
  describe ".update_hostnames" do
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
      before(:all) { described_class.update_hostnames }
      
      # it "should have delayed 3 site activations" do
      #   Delayed::Job.count.should == 4
      #   Delayed::Job.last.name.should == 'Site#activate'
      # end
      
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
      
      it "All sites should be valid" do
        [@not_public_hostname, @mixed_invalid_site, @not_local_dev_hostname1, @not_local_dev_hostname2, @duplicated_dev_hostname1, @duplicated_dev_hostname2].each do |valid_site|
          valid_site.should be_valid
        end
      end
    end
  end
  
end