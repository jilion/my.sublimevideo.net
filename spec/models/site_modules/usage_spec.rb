require 'spec_helper'

describe SiteModules::Usage do

  describe '#billable_usages' do
    before do
      Timecop.travel(2012, 5, 15)
      @site = create(:site)
    end
    after { Timecop.return }

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

  describe '#current_monthly_billable_usages.sum' do
    before do
      @site = create(:site)
      @site.reload
      @site.unmemoize_all
      create(:site_day_stat, t: @site.token, d: 1.month.ago.midnight, vv: { m: 3, e: 7, d: 10, i: 0, em: 0 })
      create(:site_day_stat, t: @site.token, d: Time.now.utc.midnight, vv: { m: 11, e: 15, d: 10, i: 0, em: 0 })
      create(:site_day_stat, t: @site.token, d: 1.month.from_now.midnight, vv: { m: 19, e: 23, d: 10, i: 0, em: 0 })
    end

    subject { @site }

    its('current_monthly_billable_usages.sum') { should eq 11 + 15 }
  end

end
