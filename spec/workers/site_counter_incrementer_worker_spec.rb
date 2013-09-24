require 'fast_spec_helper'
require 'sidekiq'
require 'sidekiq/testing'

require 'workers/site_counter_incrementer_worker'

Site = Struct.new(:params) unless defined?(Site)

describe SiteCounterIncrementerWorker do
  let(:params) { ['site_token', 'last_30_days_video_tags'] }
  let(:site) { double(Site) }

  before {
    Site.stub_chain(:where, :first) { site }
  }

  it "performs async job" do
    expect {
      described_class.perform_async(*params)
    }.to change(described_class.jobs, :size).by(1)
  end

  it "delays job in default (mysv) queue" do
    expect(described_class.get_sidekiq_options['queue']).to eq 'my-low'
  end

  it "increments site counter" do
    expect(site).to receive(:increment!).with('last_30_days_video_tags')
    described_class.new.perform(*params)
  end

end
