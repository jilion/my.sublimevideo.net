require 'spec_helper'

describe UsersTrend do

  describe ".create_trends", :addons do
    before do
      s = create(:site, state: 'active') # in trial => free
      bi = create(:design_billable_item, state: 'trial', site: s, item: @twit_design)

      s = create(:site, state: 'archived') # in trial & archived
      create(:design_billable_item, state: 'trial', site: s, item: @twit_design)

      s = create(:site, state: 'active') # not in trial but design free => free
      bi = create(:design_billable_item, state: 'subscribed', site: s, item: @twit_design)

      s = create(:site, state: 'active') # not in trial
      bi = create(:addon_plan_billable_item, state: 'subscribed', site: s, item: @logo_addon_plan_2)

      create(:user, state: 'suspended') # suspended
      create(:user, state: 'archived') # archived
    end

    it "should create users stats for states" do
      described_class.create_trends

      expect(described_class.count).to eq 1
      users_stat = described_class.last
      expect(users_stat.fr).to eq 3
      expect(users_stat.pa).to eq 1
      expect(users_stat.su).to eq 1
      expect(users_stat.ar).to eq 1
    end
  end

  describe '.json' do
    before do
      create(:users_trend, d: Time.now.utc.midnight)
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
  end

end
