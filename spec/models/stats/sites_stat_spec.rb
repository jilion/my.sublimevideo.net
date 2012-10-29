require 'spec_helper'

describe Stats::SitesStat do

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

    describe ".create_stats" do
      it "should create sites stats for states & plans" do
        described_class.create_stats
        described_class.count.should eq 1
        sites_stat = described_class.last
        sites_stat["fr"].should == { "free" => 3 }
        sites_stat["pa"].should == { "addons" => 2 }
        sites_stat["su"].should eq 1
        sites_stat["ar"].should eq 2
      end
    end

  end

end
