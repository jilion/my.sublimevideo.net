# coding: utf-8
require 'spec_helper'

describe OneTime::Site do

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
      @invalid3 = FactoryGirl.create(:site, plan_id: @free_plan.id, dev_hostnames: "127.0.0.1")
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