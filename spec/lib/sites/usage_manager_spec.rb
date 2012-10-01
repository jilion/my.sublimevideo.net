require 'spec_helper'
require File.expand_path('lib/sites/usage_manager')

describe Sites::UsageManager do
  let(:site) { create(:site) }

  describe '#set_first_billable_plays_at' do
    let(:site1) { create(:site) }
    let(:site2) { create(:site) }
    let(:site3) { create(:site) }
    let(:site4) { create(:site) }
    let(:site5) { create(:site) }
    let(:site6) { create(:site) }
    before do
      create(:site_day_stat, t: site1.token, d: 300.days.ago.midnight, vv: { m: 11 }) # > 10 main views
      create(:site_day_stat, t: site1.token, d: 400.days.ago.midnight, vv: { m: 12 }) # > 10 main views
      create(:site_day_stat, t: site2.token, d: 200.days.ago.midnight, vv: { e: 11 }) # > 10 extra views
      create(:site_day_stat, t: site3.token, d: 100.days.ago.midnight, vv: { em: 11 }) # > 10 embed views
      create(:site_day_stat, t: site4.token, d: 50.days.ago.midnight, vv: { m: 5, e: 3, em: 2 }) # > 10 views
      create(:site_day_stat, t: site5.token, d: 25.day.ago.midnight, vv: { m: 9 }) # less than 10 views
      create(:site_day_stat, t: site6.token, d: 12.day.ago.midnight, vv: { d: 11 }) # > 10 views but dev views
    end

    it 'set first_billable_plays_at to the first day with at least 10 billable views' do
      [site1, site2, site3, site4, site5, site6].each { |s| described_class.new(s).set_first_billable_plays_at }

      site1.reload.first_billable_plays_at.should eq 400.days.ago.midnight
      site2.reload.first_billable_plays_at.should eq 200.days.ago.midnight
      site3.reload.first_billable_plays_at.should eq 100.days.ago.midnight
      site4.reload.first_billable_plays_at.should eq 50.days.ago.midnight
      site5.reload.first_billable_plays_at.should be_nil
      site6.reload.first_billable_plays_at.should be_nil
    end
  end

  describe '#update_last_30_days_video_tags_counters' do
    it 'updates site video tags counter from the last 30 days' do
      create(:video_tag, st: site.token)
      create(:video_tag, st: site.token)
      create(:video_tag, st: site.token, updated_at: 31.days.ago.midnight)

      described_class.new(site).update_last_30_days_video_tags_counters

      site.reload.last_30_days_video_tags.should eq 2
    end
  end

  describe '#update_last_30_days_video_views_counters' do
    let(:site) { create(:site, last_30_days_main_video_views: 1) }
    before do
      create(:site_day_stat, t: site.token, d: 31.days.ago.midnight, vv: { m: 1, e: 5, d: 9, i: 13, em: 17 })
      create(:site_day_stat, t: site.token, d: 30.days.ago.midnight, vv: { m: 2, e: 6, d: 10, i: 14, em: 18 })
      create(:site_day_stat, t: site.token, d: 1.days.ago.midnight, vv: { m: 3, e: 7, d: 11, i: 15, em: 19 })
      create(:site_day_stat, t: site.token, d: Time.now.utc.midnight, vv: { m: 4, e: 8, d: 12, i: 16, em: 20 })
    end

    it 'updates site counters from last 30 days site stats' do
      described_class.new(site).update_last_30_days_video_views_counters

      site.last_30_days_main_video_views.should    eq 5
      site.last_30_days_extra_video_views.should   eq 13
      site.last_30_days_dev_video_views.should     eq 21
      site.last_30_days_invalid_video_views.should eq 29
      site.last_30_days_embed_video_views.should   eq 37
      site.last_30_days_billable_video_views_array.should eq [26, [0]*28, 29].flatten
    end
  end

end
