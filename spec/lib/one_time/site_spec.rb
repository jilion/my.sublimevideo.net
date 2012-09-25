# coding: utf-8
require 'spec_helper'
require 'one_time/site'

describe OneTime::Site do

  describe '.regenerate_templates' do
    before do
      create(:site)
      create(:site, state: 'archived')
      Delayed::Job.delete_all
    end

    it 'regenerates loader and license of all sites' do
      expect { described_class.regenerate_templates(loader: true, license: true) }.to change(
        Delayed::Job.where{ handler =~ '%update_loader_and_license%' }, :count
      ).by(1)
    end
  end

end
