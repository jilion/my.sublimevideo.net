require 'spec_helper'

describe SitesTrend do
  describe "with a bunch of different sites" do
    let!(:design)     { create(:design, price: 0) }
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
    end

    describe '.create_trends' do
      before {
        day = Time.now.utc.midnight.to_date
        SiteAdminStat.stub(:last_30_days_sites_with_starts).with(day, threshold: 1) { 1 }
        SiteAdminStat.stub(:last_30_days_sites_with_starts).with(day, threshold: 2) { 2 }
        SiteAdminStat.stub(:last_30_days_sites_with_starts).with(day, threshold: 100) { 100 }
      }

      it 'creates sites stats for states & plans' do
        described_class.create_trends
        described_class.count.should eq 1
        sites_stat = described_class.last
        sites_stat["fr"].should eq({ 'free' => 3 })
        sites_stat["pa"].should eq({ 'addons' => 2 })
        sites_stat["su"].should eq 1
        sites_stat["ar"].should eq 2
        sites_stat["al"].should eq({ "st1" => 1, "st2" => 2, "st100" => 100 })
      end
    end

    describe '.update_alive_sites_trends' do
      before do
        described_class.create(d: 2.day.ago.midnight, fr: { 'free' => 3 }, pa: { 'addons' => 2 }, su: 1, ar: 1)
        described_class.create(d: Time.now.utc.midnight, fr: { 'free' => 3 }, pa: { 'addons' => 2 }, su: 1, ar: 1)

        SiteAdminStat.stub(:last_30_days_sites_with_starts) { 1 }
      end

      it 'updates the existing trend to add alive sites trends' do
        described_class.where(d: 2.day.ago.midnight).first['al'].should be_nil
        described_class.where(d: Time.now.utc.midnight).first['al'].should be_nil

        described_class.update_alive_sites_trends

        described_class.where(d: 2.day.ago.midnight).first['al'].should eq({ 'st1' => 1, 'st2' => 1, 'st100' => 1 })
        described_class.where(d: Time.now.utc.midnight).first['al'].should eq({ 'st1' => 1, 'st2' => 1, 'st100' => 1 })
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
