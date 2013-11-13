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
        allow(SiteAdminStat).to receive(:last_30_days_sites_with_starts).with(day, threshold: 1) { 1 }
        allow(SiteAdminStat).to receive(:last_30_days_sites_with_starts).with(day, threshold: 2) { 2 }
        allow(SiteAdminStat).to receive(:last_30_days_sites_with_starts).with(day, threshold: 100) { 100 }
      }

      it 'creates sites stats for states & plans' do
        described_class.create_trends
        expect(described_class.count).to eq 1
        sites_stat = described_class.last
        expect(sites_stat["fr"]).to eq({ 'free' => 3 })
        expect(sites_stat["pa"]).to eq({ 'addons' => 2 })
        expect(sites_stat["su"]).to eq 1
        expect(sites_stat["ar"]).to eq 2
        expect(sites_stat["al"]).to eq({ "st1" => 1, "st2" => 2, "st100" => 100 })
      end
    end

    describe '.update_alive_sites_trends' do
      before do
        described_class.create(d: 2.day.ago.midnight, fr: { 'free' => 3 }, pa: { 'addons' => 2 }, su: 1, ar: 1)
        described_class.create(d: Time.now.utc.midnight, fr: { 'free' => 3 }, pa: { 'addons' => 2 }, su: 1, ar: 1)

        allow(SiteAdminStat).to receive(:last_30_days_sites_with_starts) { 1 }
      end

      it 'updates the existing trend to add alive sites trends' do
        expect(described_class.where(d: 2.day.ago.midnight).first['al']).to be_nil
        expect(described_class.where(d: Time.now.utc.midnight).first['al']).to be_nil

        described_class.update_alive_sites_trends

        expect(described_class.where(d: 2.day.ago.midnight).first['al']).to eq({ 'st1' => 1, 'st2' => 1, 'st100' => 1 })
        expect(described_class.where(d: Time.now.utc.midnight).first['al']).to eq({ 'st1' => 1, 'st2' => 1, 'st100' => 1 })
      end
    end
  end

  describe '.json' do
    before do
      create(:sites_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    describe '#size' do
      subject { super().size }
      it { should eq 1 }
    end
    it { expect(subject[0]['id']).to eq(Time.now.utc.midnight.to_i) }
    it { expect(subject[0]).to have_key('fr') }
    it { expect(subject[0]).to have_key('pa') }
    it { expect(subject[0]).to have_key('su') }
    it { expect(subject[0]).to have_key('ar') }
    it { expect(subject[0]).to have_key('al') }
  end
end
