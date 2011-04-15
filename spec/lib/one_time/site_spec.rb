# coding: utf-8
require 'spec_helper'

describe OneTime::Site do

  describe ".rollback_beta_sites_to_dev", :focus => true do
    before(:all) do
      @site1 = Factory(:site, plan_id: @beta_plan.id)
      @site2 = Factory(:site, plan_id: @beta_plan.id)
      @site2.update_attribute(:pending_plan_id, @paid_plan.id)
      @site3 = Factory(:site, state: 'archived', plan_id: @beta_plan.id)

      Site.update_loader_and_license(@site1.id, { loader: false, license: true })
      Site.update_loader_and_license(@site2.id, { loader: false, license: true })
      Site.update_loader_and_license(@site3.id, { loader: false, license: true })

      @old_license1 = @site1.reload.license.read
      @old_license2 = @site2.reload.license.read
      @old_license3 = @site3.reload.license.read
      puts "@site1.license.read : #{@site1.license.read}"
      puts "@site2.license.read : #{@site2.license.read}"
      puts "@site3.license.read : #{@site3.license.read}\n"

      described_class.rollback_beta_sites_to_dev

      @worker.work_off
    end

    it "should rollback beta site to active state with dev plan" do
      @site1.reload.should be_active
      @site1.should be_in_dev_plan
      @site1.license.read.should_not == @old_license1
      puts "@site1.license.read : #{@site1.license.read}"

      @site2.reload.should be_in_beta_plan
      @site2.pending_plan_id.should == @paid_plan.id
      @site2.license.read.should == @old_license2
      puts "@site2.license.read : #{@site2.license.read}"

      @site3.reload.should be_archived
      @site3.should be_in_dev_plan
      @site3.license.read.should_not == @old_license3
      puts "@site3.license.read : #{@site3.license.read}"
    end
  end

  describe ".regenerate_all_loaders_and_licenses" do
    before(:all) do
      ::Site.delete_all
      Factory(:site)
      Factory(:site)
      Factory(:site, state: 'archived')
    end

    it "should regenerate loader and license of all sites" do
      Delayed::Job.delete_all
      count_before = Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count
      lambda { described_class.regenerate_all_loaders_and_licenses }.should change(Delayed::Job, :count).by(2)
      djs = Delayed::Job.where(:handler.matches => "%update_loader_and_license%")
      djs.count.should == count_before + 2
    end
  end

end