# coding: utf-8
require 'spec_helper'

describe OneTime::Site do

  describe ".regenerate_templates" do
    before do
      create(:site)
      create(:site, state: 'archived')
    end

    it "regenerates loader and license of all sites" do
      Delayed::Job.delete_all
      lambda { described_class.regenerate_templates(loader: true, license: true) }.should change(Delayed::Job.where { handler =~ "%update_loader_and_license%" }, :count).by(1)
    end
  end

end
