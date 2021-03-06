require "spec_helper"

describe BillableItemsTrend, :addons do
  let(:site1) { create(:site) }
  let(:site2) { create(:site) }
  before do
    create(:billable_item, site: site1, item: @classic_design, state: 'subscribed')
    create(:billable_item, site: site1, item: @light_design, state: 'sponsored')
    create(:billable_item, site: site1, item: @flat_design, state: 'beta')
    create(:billable_item, site: site1, item: @twit_design, state: 'sponsored')
    create(:billable_item, site: site1, item: @html5_design, state: 'trial')

    create(:billable_item, site: site1, item: @logo_addon_plan_2, state: 'subscribed')
    create(:billable_item, site: site1, item: @stats_addon_plan_2, state: 'sponsored')
    create(:billable_item, site: site1, item: @support_addon_plan_2, state: 'suspended')

    create(:billable_item, site: site2, item: @classic_design, state: 'beta')
    create(:billable_item, site: site2, item: @light_design, state: 'trial')
    create(:billable_item, site: site2, item: @flat_design, state: 'sponsored')
    create(:billable_item, site: site2, item: @twit_design, state: 'trial')
    create(:billable_item, site: site2, item: @html5_design, state: 'suspended')

    create(:billable_item, site: site2, item: @logo_addon_plan_2, state: 'trial')
    create(:billable_item, site: site2, item: @stats_addon_plan_2, state: 'beta')
    create(:billable_item, site: site2, item: @support_addon_plan_2, state: 'sponsored')
  end

  describe '.create_trends' do
    it 'creates billable_items_stats stats for the last day' do
      described_class.create_trends
      described_class.count.should eq 1
      billable_items_stats = described_class.last
      billable_items_stats["d"].should eq Time.now.utc.midnight
      billable_items_stats["be"].should == {
        'design' => { 'classic' => 1, 'flat' => 1 },
        'stats'  => { 'realtime' => 1 }
      }
      billable_items_stats["tr"].should == {
        'design' => { 'light' => 1, 'twit' => 1, 'html5' => 1 },
        'logo'   => { 'disabled' => 1 }
      }
      billable_items_stats["sb"].should == {
        'design' => { 'classic' => 1 },
        'logo'   => { 'disabled' => 1 }
      }
      billable_items_stats["sp"].should == {
        'design'  => { 'light' => 1, 'twit' => 1, 'flat' => 1 },
        'stats'   => { 'realtime' => 1 },
        'support' => { 'vip' => 1 }
      }
      billable_items_stats["su"].should == {
        'design'  => { 'html5' => 1 },
        'support' => { 'vip' => 1 }
      }
    end
  end

  describe '.json' do
    before do
      create(:billable_items_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    its(:size) { should eq 1 }
    it { subject[0]['id'].should eq(Time.now.utc.midnight.to_i) }
    it { subject[0].should have_key('be') }
    it { subject[0].should have_key('tr') }
    it { subject[0].should have_key('sb') }
    it { subject[0].should have_key('sp') }
    it { subject[0].should have_key('su') }
  end

end
