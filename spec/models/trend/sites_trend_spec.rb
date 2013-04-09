require 'spec_helper'

describe SitesTrend do
  describe "with a bunch of different sites" do
    let!(:design)     { create(:app_design, price: 0) }
    let!(:addon_plan) { create(:addon_plan, price: 990) }
    before do
      user = create(:user)
      create(:site, user: user, state: 'active') # free
      s1 = create(:site, user: user, state: 'active') # in trial => free
      create(:design_billable_item, state: 'trial', site: s1, item: design)

      s2 = create(:site, user: user, state: 'archived') # in trial & archived
      create(:design_billable_item, state: 'trial', site: s2, item: design)

      s3 = create(:site, user: user, state: 'active') # not in trial but design free => free
      create(:design_billable_item, state: 'subscribed', site: s3, item: design)

      s4 = create(:site, user: user, state: 'active') # not in trial
      create(:addon_plan_billable_item, state: 'subscribed', site: s4, item: addon_plan)

      s5 = create(:site, user: user, state: 'active') # not in trial
      create(:addon_plan_billable_item, state: 'subscribed', site: s5, item: addon_plan)

      create(:site, user: user, state: 'suspended') # suspended
      create(:site, user: user, state: 'archived') # archived

      create(:site_day_stat, t: s1.token, d: 31.days.ago.midnight, pv: { m: 1 }, vv: { m: 1 }) # not in the last 30 days
      create(:site_day_stat, t: s2.token, d: 1.day.ago.midnight, pv: { m: 1 }, vv: { m: 1 }) # not taken in account (archived)
      create(:site_day_stat, t: s3.token, d: 30.days.ago.midnight, pv: { m: 1 }, vv: { m: 1 }) # in the last 30 days
      create(:site_day_stat, t: s4.token, d: 1.days.ago.midnight, pv: { e: 1 }, vv: { e: 1 })
      create(:site_day_stat, t: s5.token, d: 1.day.ago.midnight, pv: { em: 1 }, vv: { em: 1 })
    end

    describe '.create_trends' do
      it 'creates sites stats for states & plans' do
        described_class.create_trends
        described_class.count.should eq 1
        sites_stat = described_class.last
        sites_stat["fr"].should eq({ 'free' => 3 })
        sites_stat["pa"].should eq({ 'addons' => 2 })
        sites_stat["su"].should eq 1
        sites_stat["ar"].should eq 2
        sites_stat["al"].should eq({ 'pv' => 3, 'vv' => 3 })
      end
    end
  end

  describe '.json' do
    before do
      create(:sites_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    its(:size) { should eq 1 }
    it { subject[0]['id'].should eq(Time.now.utc.midnight.to_i) }
    it { subject[0].should have_key('fr') }
    it { subject[0].should have_key('pa') }
    it { subject[0].should have_key('su') }
    it { subject[0].should have_key('ar') }
    it { subject[0].should have_key('al') }
  end
end
