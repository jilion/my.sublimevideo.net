# coding: utf-8
require 'spec_helper'

describe OneTime::Site do

  describe ".rollback_beta_sites_to_dev" do
    before(:all) do
      @site1 = FactoryGirl.create(:site, plan_id: @beta_plan.id)
      @site2 = FactoryGirl.create(:site, plan_id: @beta_plan.id)
      @site2.update_attribute(:pending_plan_id, @paid_plan.id)
      @site3 = FactoryGirl.create(:site, state: 'archived', plan_id: @beta_plan.id)

      Site.update_loader_and_license(@site1.id, { loader: false, license: true })
      Site.update_loader_and_license(@site2.id, { loader: false, license: true })
      Site.update_loader_and_license(@site3.id, { loader: false, license: true })

      @old_license1 = @site1.reload.license.read
      @old_license2 = @site2.reload.license.read
      @old_license3 = @site3.reload.license.read
      # puts "@site1.license.read : #{@site1.license.read}"
      # puts "@site2.license.read : #{@site2.license.read}"
      # puts "@site3.license.read : #{@site3.license.read}\n"
    end

    it "should rollback beta site to active state with dev plan" do
      expect { described_class.rollback_beta_sites_to_dev }.to change(Delayed::Job, :count).by(2)
      @worker.work_off

      @site1.reload.should be_active
      @site1.should be_in_dev_plan
      @site1.license.read.should_not == @old_license1
      # puts "@site1.license.read : #{@site1.license.read}"

      @site2.reload.should be_in_beta_plan
      @site2.pending_plan_id.should == @paid_plan.id
      @site2.license.read.should == @old_license2
      # puts "@site2.license.read : #{@site2.license.read}"

      @site3.reload.should be_archived
      @site3.should be_in_dev_plan
      @site3.license.read.should_not == @old_license3
      # puts "@site3.license.read : #{@site3.license.read}"
    end
  end

  describe ".regenerate_all_loaders_and_licenses" do
    before(:all) do
      ::Site.delete_all
      FactoryGirl.create(:site)
      FactoryGirl.create(:site)
      FactoryGirl.create(:site, state: 'archived')
    end

    it "regenerates loader and license of all sites" do
      Delayed::Job.delete_all
      count_before = Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count
      lambda { described_class.regenerate_all_loaders_and_licenses }.should change(Delayed::Job, :count).by(2)
      djs = Delayed::Job.where(:handler.matches => "%update_loader_and_license%")
      djs.count.should == count_before + 2
    end
  end

  describe ".move_local_ip_from_hostname_and_extra_domains_to_dev_domains" do
    before(:all) do
      ::Site.delete_all
      @invalid1 = FactoryGirl.create(:site, dev_hostnames: "localhost")
      @invalid1.update_attribute(:extra_hostnames, "google.com, 172.16.4.165")
      @invalid2 = FactoryGirl.create(:site, dev_hostnames: "127.0.0.1")
      @invalid2.update_attribute(:extra_hostnames, "172.16.4.165")
      @invalid3 = FactoryGirl.create(:site, plan_id: @dev_plan.id, dev_hostnames: "127.0.0.1")
      @invalid3.update_attribute(:hostname, "172.16.4.165")

      @valid1 = FactoryGirl.create(:site, dev_hostnames: "localhost", extra_hostnames: "google.com")
      @valid2 = FactoryGirl.create(:site, dev_hostnames: "127.0.0.1", extra_hostnames: "google.com")

      @archived = FactoryGirl.create(:site, state: 'archived', dev_hostnames: nil)
      @archived.update_attribute(:extra_hostnames, "172.16.4.165")
    end

    it "moves local domains present in extra domains into dev domains" do
      described_class.move_local_ip_from_hostname_and_extra_domains_to_dev_domains

      @invalid1.reload.dev_hostnames.should == "172.16.4.165, localhost"
      @invalid1.extra_hostnames.should == "google.com"
      @invalid2.reload.dev_hostnames.should == "127.0.0.1, 172.16.4.165"
      @invalid2.extra_hostnames.should == ""
      @invalid3.reload.dev_hostnames.should == "127.0.0.1, 172.16.4.165"
      @invalid3.extra_hostnames.should == ""
      @invalid3.hostname.should == ""

      @valid1.reload.dev_hostnames.should == "localhost"
      @valid1.extra_hostnames.should == "google.com"
      @valid2.reload.dev_hostnames.should == "127.0.0.1"
      @valid2.extra_hostnames.should == "google.com"
    end
  end

end