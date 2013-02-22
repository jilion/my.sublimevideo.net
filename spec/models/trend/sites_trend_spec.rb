require 'spec_helper'

describe SitesTrend do

  describe "with a bunch of different sites", :addons do
    before do
      user = create(:user)
      create(:site, user: user, state: 'active') # free
      s = create(:site, user: user, state: 'active') # in trial => free
      create(:design_billable_item, state: 'trial', site: s, item: @twit_design)

      s = create(:site, user: user, state: 'archived') # in trial & archived
      create(:design_billable_item, state: 'trial', site: s, item: @twit_design)

      s = create(:site, user: user, state: 'active') # not in trial but design free => free
      create(:design_billable_item, state: 'subscribed', site: s, item: @twit_design)

      s = create(:site, user: user, state: 'active') # not in trial
      create(:addon_plan_billable_item, state: 'subscribed', site: s, item: @logo_addon_plan_2)

      s = create(:site, user: user, state: 'active') # not in trial
      create(:addon_plan_billable_item, state: 'subscribed', site: s, item: @support_addon_plan_2)

      create(:site, user: user, state: 'suspended') # suspended
      create(:site, user: user, state: 'archived') # archived
    end

    describe ".create_trends" do
      it "should create sites stats for states & plans" do
        described_class.create_trends
        described_class.count.should eq 1
        sites_stat = described_class.last
        sites_stat["fr"].should == { "free" => 3 }
        sites_stat["pa"].should == { "addons" => 2 }
        sites_stat["su"].should eq 1
        sites_stat["ar"].should eq 2
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
  end

end