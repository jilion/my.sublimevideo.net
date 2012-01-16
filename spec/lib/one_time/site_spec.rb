# coding: utf-8
require 'spec_helper'

describe OneTime::Site do

  describe ".regenerate_all_loaders_and_licenses" do
    before(:all) do
      ::Site.delete_all
      Factory.create(:site)
      Factory.create(:site)
      Factory.create(:site, state: 'archived')
    end

    it "regenerates loader and license of all sites" do
      Delayed::Job.delete_all
      count_before = Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count
      lambda { described_class.regenerate_all_loaders_and_licenses }.should change(Delayed::Job, :count).by(2)
      djs = Delayed::Job.where(:handler.matches => "%update_loader_and_license%")
      djs.should have(count_before + 2).items
    end
  end

end
