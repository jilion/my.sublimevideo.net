require 'spec_helper'

describe Stats::UsersStat do

  describe ".create_stats", :addons do
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
      described_class.create_stats

      described_class.count.should eq 1
      users_stat = described_class.last
      users_stat.fr.should eq 3
      users_stat.pa.should eq 1
      users_stat.su.should eq 1
      users_stat.ar.should eq 1
    end
  end

  describe '.json' do
    before do
      create(:users_stat, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    its(:size) { should eq 1 }
    it { subject[0]['id'].should eq(Time.now.utc.midnight.to_i) }
    it { subject[0].should have_key('fr') }
    it { subject[0].should have_key('pa') }
    it { subject[0].should have_key('su') }
    it { subject[0].should have_key('ar') }
  end

end
