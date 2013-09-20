require 'fast_spec_helper'
require 'sidekiq'
require 'sidekiq/testing'

require 'workers/video_stats_merger_worker'
require 'services/video_stats_merger'

describe VideoStatsMergerWorker do
  let(:params) { ['site_token', 'uid', 'old_uid'] }

  before {
    VideoStatsMerger.stub_chain(:new, :merge!)
    Librato.stub(:increment)
  }

  it "performs async job" do
    expect {
      described_class.perform_async(*params)
    }.to change(described_class.jobs, :size).by(1)
  end

  it "delays job in low (mysv) queue" do
    described_class.get_sidekiq_options['queue'].should eq 'my-low'
  end

  it "merges video stats" do
    VideoStatsMerger.should_receive(:new).with(*params) { |mock|
      mock.should_receive(:merge!)
      mock
    }
    described_class.new.perform(*params)
  end

  it "increments Librato 'video_stats.merge' metric" do
    Librato.should_receive(:increment).once.with('video_stats.merge')
    described_class.new.perform(*params)
  end

end
