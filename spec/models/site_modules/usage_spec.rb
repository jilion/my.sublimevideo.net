require 'spec_helper'

describe SiteModules::Usage do
  let(:active_site)   { create(:site, state: 'active') }
  let(:archived_site) { create(:site, state: 'archived') }

  describe '.update_last_30_days_counters_for_not_archived_sites' do
    it 'calls #update_last_30_days_video_views_counters on each non-archived sites' do
      create(:site_day_stat, t: active_site.token, d: Time.utc(2011,1,15).midnight, vv: { m: 6 })
      create(:site_day_stat, t: archived_site.token, d: Time.utc(2011,1,15).midnight, vv: { m: 6 })

      Timecop.travel(Time.utc(2011,1,31, 12)) do
        Site.update_last_30_days_counters_for_not_archived_sites
        active_site.reload.last_30_days_main_video_views.should eq 6
        archived_site.reload.last_30_days_main_video_views.should eq 0
      end
    end

    it 'calls #update_last_30_days_video_tags_counters on each non-archived sites' do
      create(:video_tag, site: active_site)
      create(:video_tag, site: archived_site)

      Timecop.travel(1.week.from_now) do
        Site.update_last_30_days_counters_for_not_archived_sites
        active_site.reload.last_30_days_video_tags.should eq 1
        archived_site.reload.last_30_days_video_tags.should eq 0
      end
    end
  end

  describe '.set_first_billable_plays_at_for_not_archived_sites' do
    let(:site1) { create(:site, state: 'active') }
    let(:site2) { create(:site, state: 'archived') }
    let(:site3) { create(:site, state: 'active', first_billable_plays_at: 100.days.ago.midnight) }

    before do
      create(:site_day_stat, t: site1.token, d: 400.days.ago.midnight, vv: { m: 11 }) # > 10 main views
      create(:site_day_stat, t: site2.token, d: 200.days.ago.midnight, vv: { e: 11 }) # > 10 extra views
      create(:site_day_stat, t: site3.token, d: 50.days.ago.midnight, vv: { e: 11 }) # > 10 extra views
    end

    it 'calls #set_first_billable_plays_at on each non-archived sites' do
      Site.set_first_billable_plays_at_for_not_archived_sites

      site1.reload.first_billable_plays_at.should eq 400.days.ago.midnight
      site2.reload.first_billable_plays_at.should be_nil
      site3.reload.first_billable_plays_at.should eq 100.days.ago.midnight
    end
  end

  describe '#update_last_30_days_video_tags_counters' do
    it 'updates site video tags counter from the last 30 days' do
      create(:video_tag, site: active_site)
      create(:video_tag, site: active_site)
      create(:video_tag, site: active_site, updated_at: 31.days.ago.midnight)

      active_site.update_last_30_days_video_tags_counters
      active_site.reload.last_30_days_video_tags.should eq 2
    end
  end

  describe '#update_last_30_days_video_views_counters' do
    before do
      @site = create(:site, last_30_days_main_video_views: 1)
      create(:site_day_stat, t: @site.token, d: 31.days.ago.midnight, vv: { m: 1, e: 5, d: 9, i: 13, em: 17 })
      create(:site_day_stat, t: @site.token, d: 30.days.ago.midnight, vv: { m: 2, e: 6, d: 10, i: 14, em: 18 })
      create(:site_day_stat, t: @site.token, d: 1.days.ago.midnight, vv: { m: 3, e: 7, d: 11, i: 15, em: 19 })
      create(:site_day_stat, t: @site.token, d: Time.now.utc.midnight, vv: { m: 4, e: 8, d: 12, i: 16, em: 20 })
    end

    it 'updates site counters from last 30 days site stats' do
      @site.update_last_30_days_video_views_counters
      @site.last_30_days_main_video_views.should    eq 5
      @site.last_30_days_extra_video_views.should   eq 13
      @site.last_30_days_dev_video_views.should     eq 21
      @site.last_30_days_invalid_video_views.should eq 29
      @site.last_30_days_embed_video_views.should   eq 37
      @site.last_30_days_billable_video_views_array.should eq [26, [0]*28, 29].flatten
    end
  end

  describe '#set_first_billable_plays_at' do
    let(:site1) { create(:site) }
    let(:site2) { create(:site) }
    let(:site3) { create(:site) }
    let(:site4) { create(:site) }
    let(:site5) { create(:site) }
    let(:site6) { create(:site) }
    let(:site7) { create(:site) }
    let(:site8) { create(:site) }

    before do
      create(:site_day_stat, t: site1.token, d: 300.days.ago.midnight, vv: { m: 11 }) # > 10 main views
      create(:site_day_stat, t: site1.token, d: 400.days.ago.midnight, vv: { m: 12 }) # > 10 main views
      create(:site_day_stat, t: site2.token, d: 200.days.ago.midnight, vv: { e: 11 }) # > 10 extra views
      create(:site_day_stat, t: site3.token, d: 100.days.ago.midnight, vv: { em: 11 }) # > 10 embed views
      create(:site_day_stat, t: site4.token, d: 50.days.ago.midnight, vv: { m: 5, e: 3, em: 2 }) # > 10 views
      create(:site_day_stat, t: site5.token, d: 25.day.ago.midnight, vv: { m: 9 }) # less than 10 views
      create(:site_day_stat, t: site6.token, d: 12.day.ago.midnight, vv: { d: 11 }) # > 10 views but dev views
      create(:site_usage, day: 500.days.ago.midnight, site_id: site7.id, main_player_hits: 4, extra_player_hits: 2, main_player_hits_cached: 2, extra_player_hits_cached: 2)
      create(:site_usage, day: 600.days.ago.midnight, site_id: site8.id, main_player_hits: 9, dev_player_hits: 12)
    end

    it 'set first_billable_plays_at to the first day with at least 10 billable views' do
      [site1, site2, site3, site4, site5, site6, site7, site8].each { |s| s.set_first_billable_plays_at }

      site1.reload.first_billable_plays_at.should eq 400.days.ago.midnight
      site2.reload.first_billable_plays_at.should eq 200.days.ago.midnight
      site3.reload.first_billable_plays_at.should eq 100.days.ago.midnight
      site4.reload.first_billable_plays_at.should eq 50.days.ago.midnight
      site5.reload.first_billable_plays_at.should be_nil
      site6.reload.first_billable_plays_at.should be_nil
      site7.reload.first_billable_plays_at.should eq 500.days.ago.midnight
      site8.reload.first_billable_plays_at.should be_nil
    end
  end

  describe '#billable_usages' do
    before { Timecop.travel(15.days.ago) { @site = create(:site) } }

    before do
      @site.unmemoize_all
      create(:site_day_stat, t: @site.token, d: 1.day.ago.midnight, vv: { m: 4 })
      create(:site_day_stat, t: @site.token, d: 2.day.ago.midnight, vv: { m: 3 })
      create(:site_day_stat, t: @site.token, d: 3.day.ago.midnight, vv: { m: 2 })
      create(:site_day_stat, t: @site.token, d: 4.day.ago.midnight, vv: { m: 0 })
      create(:site_day_stat, t: @site.token, d: 5.day.ago.midnight, vv: { m: 1 })
      create(:site_day_stat, t: @site.token, d: 6.day.ago.midnight, vv: { m: 0 })
      create(:site_day_stat, t: @site.token, d: 7.day.ago.midnight, vv: { m: 0 })
    end

    describe '#current_monthly_billable_usages' do
      specify { @site.current_monthly_billable_usages.should eq [0, 0, 1, 0, 2, 3, 4] }
    end

    it 'last_30_days_billable_usages should skip first zeros' do
      @site.last_30_days_billable_usages.should eq [1, 0, 2, 3, 4]
    end
  end

  describe '#current_monthly_billable_usages.sum & #current_percentage_of_plan_used' do
    before do
      @site = create(:site)
      @site.reload
      @site.unmemoize_all
      create(:site_day_stat, t: @site.token, d: Time.utc(2011,1,30).midnight, vv: { m: 3, e: 7, d: 10, i: 0, em: 0 })
      create(:site_day_stat, t: @site.token, d: Time.utc(2011,3,30).midnight, vv: { m: 11, e: 15, d: 10, i: 0, em: 0 })
      create(:site_day_stat, t: @site.token, d: Time.utc(2011,4,30).midnight, vv: { m: 19, e: 23, d: 10, i: 0, em: 0 })
    end

    context 'with monthly plan' do
      before do
        @site.plan.cycle            = 'month'
        @site.plan.video_views      = 100
        @site.trial_started_at      = Time.utc(2011,1,20)
        @site.plan_cycle_started_at = Time.utc(2011,3,20)
        @site.plan_cycle_ended_at   = Time.utc(2011,4,20)
        @site.plan.save!
        @site.save!
        Timecop.travel(Time.utc(2011,3,25))
      end
      after { Timecop.return }
      subject { @site }

      its('current_monthly_billable_usages.sum') { should eq 11 + 15 }
      its(:current_percentage_of_plan_used)      { should eq 26 / 100.0 }
    end

    context 'with monthly plan and overage' do
      before do
        @site.plan.cycle            = 'month'
        @site.plan.video_views      = 10
        @site.trial_started_at      = Time.utc(2011,1,20)
        @site.plan_cycle_started_at = Time.utc(2011,4,20)
        @site.plan_cycle_ended_at   = Time.utc(2011,5,20)
        @site.plan.save!
        @site.save!
        Timecop.travel(Time.utc(2011,4,25))
      end
      after { Timecop.return }
      subject { @site }

      its('current_monthly_billable_usages.sum') { should eq 19 + 23 }
      its(:current_percentage_of_plan_used)      { should eq 1 }
    end

    context 'with yearly plan' do
      before do
        @site.plan.cycle            = 'year'
        @site.plan.video_views      = 100
        @site.trial_started_at      = Time.utc(2011,1,20)
        @site.plan_cycle_started_at = Time.utc(2011,1,20)
        @site.plan_cycle_ended_at   = Time.utc(2012,1,20)
        @site.plan.save!
        @site.save!
        Timecop.travel(Time.utc(2011,3,25))
      end
      after { Timecop.return }
      subject { @site }

      its('current_monthly_billable_usages.sum') { should eq 11 + 15 }
      its(:current_percentage_of_plan_used)      { should eq 26 / 100.0 }
    end

    context 'with yearly plan (other date)' do
      before do
        @site.plan.cycle            = 'year'
        @site.plan.video_views      = 1000
        @site.trial_started_at      = Time.utc(2011,1,20)
        @site.plan_cycle_started_at = Time.utc(2011,1,20)
        @site.plan_cycle_ended_at   = Time.utc(2012,1,20)
        @site.plan.save!
        @site.save!
        Timecop.travel(Time.utc(2011,1,31))
      end
      after { Timecop.return }
      subject { @site }

      its('current_monthly_billable_usages.sum') { should eq 3 + 7 }
      its(:current_percentage_of_plan_used)      { should eq 10 / 1000.0 }
    end
  end

  describe '#current_percentage_of_plan_used', :plans do
    it 'should return 0 if plan video_views is 0' do
      site = create(:site, plan_id: @free_plan.id)
      site.current_percentage_of_plan_used.should == 0
    end
  end

  describe '#percentage_of_days_over_daily_limit(60)', :plans do
    context 'with free_plan' do
      subject { create(:site, plan_id: @free_plan.id) }

      its(:percentage_of_days_over_daily_limit) { should eq 0 }
    end

    context 'with paid plan', :plans do
      before do
        @site = create(:site, plan_id: create(:plan, video_views: 30 * 300).id, first_paid_plan_started_at: Time.utc(2011,1,1))
      end

      describe 'with 1 historic day and 1 over limit' do
        before do
          create(:site_day_stat, t: @site.token, d: Time.utc(2011,1,1).midnight, vv: { m: 200, e: 200, d: 200, i: 0, em: 0 })
          Timecop.travel(Time.utc(2011,1,2))
        end
        after { Timecop.return }
        subject { @site }

        its(:percentage_of_days_over_daily_limit) { should eq 1.0 }
      end

      describe 'with 2 historic days and 1 over limit' do
        before do
          create(:site_day_stat, t: @site.token, d: Time.utc(2011,1,1).midnight, vv: { m: 400 })
          create(:site_day_stat, t: @site.token, d: Time.utc(2011,1,2).midnight, vv: { m: 300 })
          Timecop.travel(Time.utc(2011,1,3))
        end
        after { Timecop.return }
        subject { @site }

        its(:percentage_of_days_over_daily_limit) { should eq 0.5 }
      end

      describe 'with 5 historic days and 2 over limit' do
        before do
          create(:site_day_stat, t: @site.token, d: Time.utc(2011,1,1).midnight, vv: { m: 400 })
          create(:site_day_stat, t: @site.token, d: Time.utc(2011,1,2).midnight, vv: { m: 300 })
          create(:site_day_stat, t: @site.token, d: Time.utc(2011,1,3).midnight, vv: { m: 500 })
          Timecop.travel(Time.utc(2011,1,6))
        end
        after { Timecop.return }
        subject { @site }

        its(:percentage_of_days_over_daily_limit) { should eq 2 / 5.0 }
      end

      describe 'with >60 historic days and 2 over limit' do
        before do
          create(:site_day_stat, t: @site.token, d: Time.utc(2011,1,1).midnight, vv: { m: 400 })
          create(:site_day_stat, t: @site.token, d: Time.utc(2011,2,1).midnight, vv: { m: 500 })
          create(:site_day_stat, t: @site.token, d: Time.utc(2011,3,1).midnight, vv: { m: 500 })
          Timecop.travel(Time.utc(2011,4,1))
        end
        after { Timecop.return }
        subject { @site }

        its(:percentage_of_days_over_daily_limit) { should eq (2 / 60.0).round(2) }
      end
    end
  end

end
