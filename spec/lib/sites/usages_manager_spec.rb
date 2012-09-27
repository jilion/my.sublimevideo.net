require 'fast_spec_helper'
require File.expand_path('lib/sites/usages_manager')

Site = Class.new unless defined?(Site)

describe Sites::UsagesManager do
  let(:site)   { stub }
  let(:usage_manager) { stub }

  describe '.update_last_30_days_counters_for_not_archived_sites' do
    it 'calls #update_last_30_days_video_tags_counters and #update_last_30_days_video_views_counters on each non-archived sites' do
      Site.stub_chain(:not_archived, :find_each).and_yield(site)

      Sites::UsageManager.should_receive(:new).with(site) { usage_manager }
      usage_manager.should_receive(:update_last_30_days_video_tags_counters)
      usage_manager.should_receive(:update_last_30_days_video_views_counters)

      described_class.update_last_30_days_counters_for_not_archived_sites
    end
  end

  describe '.set_first_billable_plays_at_for_not_archived_sites' do
    it 'calls #set_first_billable_plays_at on each non-archived sites' do
      Site.stub_chain(:not_archived, :where, :find_each).and_yield(site)

      Sites::UsageManager.should_receive(:new).with(site) { usage_manager }
      usage_manager.should_receive(:set_first_billable_plays_at)

      described_class.set_first_billable_plays_at_for_not_archived_sites
    end
  end

end
