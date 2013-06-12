require 'fast_spec_helper'
require 'config/sidekiq'

require 'site_admin_pages_migrator_worker'

describe SiteAdminPagesMigratorWorker do
  it "performs async job" do
    expect {
      SiteAdminPagesMigratorWorker.perform_async('site_token', {})
    }.to change(SiteAdminPagesMigratorWorker.jobs, :size).by(1)
  end

  it "delays job in stats (stsv) queue" do
    SiteAdminPagesMigratorWorker.get_sidekiq_options['queue'].should eq 'stats'
  end
end
