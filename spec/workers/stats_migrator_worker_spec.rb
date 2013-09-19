require 'fast_spec_helper'
require 'config/sidekiq'

require 'stats_migrator_worker'

describe StatsMigratorWorker do

  it "performs async job" do
    expect {
      described_class.perform_async('Stat::Site::Day', {})
    }.to change(described_class.jobs, :size).by(1)
  end

  it "delays job in stats (stsv) queue" do
    described_class.get_sidekiq_options['queue'].should eq 'stats-migration'
  end

end
