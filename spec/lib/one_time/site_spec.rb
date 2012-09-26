# coding: utf-8
require 'spec_helper'
require 'one_time/site'

describe OneTime::Site do

  describe '.regenerate_templates' do
    before do
      create(:site)
      create(:site, state: 'archived')
    end

    it 'regenerates loader and license of all sites' do
      -> { described_class.regenerate_templates(loader: true, license: true) }.should delay('%update_loader_and_license%')
    end
  end

end
