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
      expect(described_class.count).to eq 1
      billable_items_stats = described_class.last
      expect(billable_items_stats["d"]).to eq Time.now.utc.midnight
      expect(billable_items_stats["be"]).to eq({
        'design' => { 'classic' => 1, 'flat' => 1 },
        'stats'  => { 'realtime' => 1 }
      })
      expect(billable_items_stats["tr"]).to eq({
        'design' => { 'light' => 1, 'twit' => 1, 'html5' => 1 },
        'logo'   => { 'disabled' => 1 }
      })
      expect(billable_items_stats["sb"]).to eq({
        'design' => { 'classic' => 1 },
        'logo'   => { 'disabled' => 1 }
      })
      expect(billable_items_stats["sp"]).to eq({
        'design'  => { 'light' => 1, 'twit' => 1, 'flat' => 1 },
        'stats'   => { 'realtime' => 1 },
        'support' => { 'vip' => 1 }
      })
      expect(billable_items_stats["su"]).to eq({
        'design'  => { 'html5' => 1 },
        'support' => { 'vip' => 1 }
      })
    end
  end

  describe '.json' do
    before do
      create(:billable_items_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    describe '#size' do
      subject { super().size }
      it { should eq 1 }
    end
    it { expect(subject[0]['id']).to eq(Time.now.utc.midnight.to_i) }
    it { expect(subject[0]).to have_key('be') }
    it { expect(subject[0]).to have_key('tr') }
    it { expect(subject[0]).to have_key('sb') }
    it { expect(subject[0]).to have_key('sp') }
    it { expect(subject[0]).to have_key('su') }
  end

end
