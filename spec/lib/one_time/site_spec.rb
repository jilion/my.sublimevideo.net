# coding: utf-8
require 'spec_helper'

describe OneTime::Site do

  describe ".regenerate_all_loaders_and_licenses" do
    before do
      Factory.create(:site)
      Factory.create(:site)
      Factory.create(:site, state: 'archived')
    end

    it "regenerates loader and license of all sites" do
      Delayed::Job.delete_all
      lambda { described_class.regenerate_all_loaders_and_licenses }.should change(Delayed::Job.where { handler =~ "%update_loader_and_license%" }, :count).by(2)
    end
  end

end
