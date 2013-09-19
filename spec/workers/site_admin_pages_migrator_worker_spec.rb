require 'fast_spec_helper'
require 'config/sidekiq'

require 'site_admin_pages_migrator_worker'

describe SiteAdminPagesMigratorWorker do

  it "performs async job" do
    expect {
      described_class.perform_async('site_token', {})
    }.to change(described_class.jobs, :size).by(1)
  end

  it "delays job in stats (stsv) queue" do
    described_class.get_sidekiq_options['queue'].should eq 'stats-migration'
  end

end
