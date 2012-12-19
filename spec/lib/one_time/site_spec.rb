# coding: utf-8
require 'spec_helper'
require 'one_time/site'

describe OneTime::Site do

  describe '.regenerate_templates' do
    let!(:site) { create(:site) }
    let!(:archived_site) { create(:site, state: 'archived') }

    it 'regenerates loader and license of all sites' do
      Service::Loader.should delay(:update_all_stages!).with(site.id)
      described_class.regenerate_templates(loaders: true)
      Service::Settings.should delay(:update_all_types!).with(site.id)
      described_class.regenerate_templates(settings: true)
    end
  end

end

def create_plans
  plans_attributes = [
    { name: "free",      cycle: "none",  video_views: 0,         stats_retention_days: 0,   price: 0,    support_level: 0 },
    { name: "sponsored", cycle: "none",  video_views: 0,         stats_retention_days: nil, price: 0,    support_level: 0 },
    { name: "trial",     cycle: "none",  video_views: 0,         stats_retention_days: nil, price: 0,    support_level: 2 },
    { name: "plus",      cycle: "month", video_views: 200_000,   stats_retention_days: 365, price: 990,  support_level: 1 },
    { name: "premium",   cycle: "month", video_views: 1_000_000, stats_retention_days: nil, price: 4990, support_level: 2 },
    { name: "plus",       cycle: "year",  video_views: 200_000,    stats_retention_days: 365, price: 9900,  support_level: 1 },
    { name: "premium",    cycle: "year",  video_views: 1_000_000,  stats_retention_days: nil, price: 49900, support_level: 2 },
    { name: "custom - 1", cycle: "year",  video_views: 10_000_000, stats_retention_days: nil, price: 99900, support_level: 2 }
  ]
  plans_attributes.each { |attributes| Plan.create!(attributes) }
end
