# coding: utf-8
require 'spec_helper'

describe OneTime::Site do

  describe ".set_beta_plan", focus: true do
    before(:all) do
      @active_invalid   = Factory.build(:new_site, plan: nil, state: 'active', hostname: 'jilion.local').tap { |s| s.save(validate: false) }
      @archived_invalid = Factory.build(:new_site, plan: nil, state: 'archived', hostname: 'jilion.local').tap { |s| s.save(validate: false) }
      @invalid1         = Factory.build(:new_site, plan: nil, state: 'active', hostname: nil).tap { |s| s.save(validate: false) }
      @invalid2         = Factory.build(:new_site, plan: nil, state: 'active', hostname: '').tap { |s| s.save(validate: false) }
    end

    context "actually test the method for all sites" do
      before(:all) { described_class.set_beta_plan }

      it "should set all sites plan to beta" do
        @active_invalid.reload.should be_in_beta_plan
        @archived_invalid.reload.should be_in_beta_plan
        @invalid1.reload.should be_in_dev_plan
        @invalid2.reload.should be_in_dev_plan
      end
    end
  end

  describe ".update_hostnames" do
    context "on all sites" do
      before(:all) do
        @not_public_hostname      = Factory.build(:new_site, plan: @beta_plan, hostname: 'jilion.local').tap { |s| s.save(validate: false) }
        @not_local_dev_hostname1  = Factory.build(:new_site, plan: @beta_plan, hostname: 'jilion.com', dev_hostnames: 'localhost, jilion.net').tap { |s| s.save(validate: false) }
        @not_local_dev_hostname2  = Factory.build(:new_site, plan: @beta_plan, hostname: 'jilion.com', dev_hostnames: 'jilion.net, jilion.org').tap { |s| s.save(validate: false) }
        @duplicated_dev_hostname1 = Factory.build(:new_site, plan: @beta_plan, hostname: '127.0.0.1', dev_hostnames: 'localhost, 127.0.0.1').tap { |s| s.save(validate: false) }
        @duplicated_dev_hostname2 = Factory.build(:new_site, plan: @beta_plan, hostname: 'jilion.com', dev_hostnames: 'localhost, 127.0.0.1, 127.0.0.1, localhost').tap { |s| s.save(validate: false) }
        @mixed_invalid_site       = Factory.build(:new_site, plan: @beta_plan, hostname: 'jilion.local', dev_hostnames: 'localhost, jilion.local, 127.0.0.1, jilion.net, jilion.com').tap { |s| s.save(validate: false) }
        @mixed_invalid_site2       = Factory.build(:new_site, plan: @beta_plan, hostname: 'jilion.local', dev_hostnames: 'localhost, jilion.local, 127.0.0.1, jilion.net').tap { |s| s.save(validate: false) }
      end

      it "all sites created should be invalid" do
        [@not_public_hostname, @not_local_dev_hostname1, @not_local_dev_hostname2, @duplicated_dev_hostname1, @duplicated_dev_hostname2, @mixed_invalid_site, @mixed_invalid_site2].each do |invalid_site|
          invalid_site.should_not be_valid
        end
      end

      context "actually test the method" do
        before(:all) { described_class.update_hostnames }

        it "should not modify site when hostname is invalid" do
          @not_public_hostname.reload.hostname.should == nil
          @not_public_hostname.dev_hostnames.should   == '127.0.0.1, jilion.local, localhost'
          @not_public_hostname.extra_hostnames.should == nil
        end

        it "should move dev hostnames that belong to extra hostnames" do
          @not_local_dev_hostname1.reload.hostname.should == 'jilion.com'
          @not_local_dev_hostname1.dev_hostnames.should   == 'localhost'
          @not_local_dev_hostname1.extra_hostnames.should == 'jilion.net'
        end

        it "should move dev hostnames that belong to extra hostnames (bis)" do
          @not_local_dev_hostname2.reload.hostname.should == 'jilion.com'
          @not_local_dev_hostname2.dev_hostnames.should   == '127.0.0.1, localhost'
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

        it "should not remove hostname when hostname is invalid and move it to dev, move dev hostnames that belong to extra hostnames, remove duplicate dev domain, set hostname to first extra hostname" do
          @mixed_invalid_site.reload.hostname.should == 'jilion.net'
          @mixed_invalid_site.dev_hostnames.should   == '127.0.0.1, jilion.local, localhost'
          @mixed_invalid_site.extra_hostnames.should == 'jilion.com'
        end

        it "should not remove hostname when hostname is invalid and move it to dev, move dev hostnames that belong to extra hostnames, remove duplicate dev domain" do
          @mixed_invalid_site2.reload.hostname.should == 'jilion.net'
          @mixed_invalid_site2.dev_hostnames.should   == '127.0.0.1, jilion.local, localhost'
          @mixed_invalid_site2.extra_hostnames.should == nil
        end

        # all beta sites will not necessarily be valid since some will have a blank hostname while it's not valid for site in beta plan
        pending "all sites should be valid" do
          [@not_public_hostname.reload, @not_local_dev_hostname1.reload, @not_local_dev_hostname2.reload, @duplicated_dev_hostname1.reload, @duplicated_dev_hostname2.reload, @mixed_invalid_site.reload].each do |valid_site|
            valid_site.should be_valid
          end
        end
      end
    end

  end

  describe ".rollback_beta_sites_to_dev" do
    before(:all) do
      @site_1 = Factory(:site, plan_id: @beta_plan.id)
      @site_2 = Factory(:site, state: 'archived')
      described_class.rollback_beta_sites_to_dev
      @worker.work_off
    end

    it "should rollback beta site to active state with dev plan" do
      @site_1.reload.should be_active
      @site_1.should be_in_dev_plan
      @site_2.reload.should be_archived
    end
  end

end