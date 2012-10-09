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
      -> { described_class.regenerate_templates(loaders: true) }.should delay('%Service::Loader%update_all_modes%')
      -> { described_class.regenerate_templates(settings: true) }.should delay('%Service::Settings%update_all_types%')
    end
  end

end
