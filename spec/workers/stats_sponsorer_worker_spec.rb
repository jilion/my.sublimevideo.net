require 'fast_spec_helper'
require 'sidekiq'
require 'sidekiq/testing'

require 'workers/stats_sponsorer_worker'

Site = Struct.new(:params) unless defined?(Site)
SiteManager = Class.new unless defined?(SiteManager)
AddonPlan = Class.new unless defined?(AddonPlan)

describe StatsSponsorerWorker do
  let(:params) { ['site_token'] }
  let(:site) { double(Site) }
  let(:site_manager) { double(Site) }

  before {
    Site.stub_chain(:where, :first) { site }
    SiteManager.stub(:new) { site_manager }
  }

  it "performs async job" do
    expect {
      described_class.perform_async(*params)
    }.to change(described_class.jobs, :size).by(1)
  end

  it "delays job in low (mysv) queue" do
    expect(described_class.get_sidekiq_options['queue']).to eq 'my-low'
  end

  it "sponsorize stats addon" do
    expect(AddonPlan).to receive(:get).with('stats', 'realtime') { double(id: 1) }
    expect(site_manager).to receive(:update_billable_items).with({}, { 'stats' => 1 }, { force: 'sponsored' })
    described_class.new.perform(*params)
  end

end
