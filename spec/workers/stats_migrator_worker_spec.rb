require 'fast_spec_helper'
require 'config/sidekiq'

require 'stats_migrator_worker'

describe StatsMigratorWorker do

  it "performs async job" do
    expect {
      StatsMigratorWorker.perform_async('Stat::Site::Day', {})
    }.to change(StatsMigratorWorker.jobs, :size).by(1)
  end

  it "delays job in stats (stsv) queue" do
    StatsMigratorWorker.get_sidekiq_options['queue'].should eq 'stats'
  end
end
