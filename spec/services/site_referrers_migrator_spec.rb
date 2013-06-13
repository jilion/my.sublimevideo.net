require 'fast_spec_helper'

require 'site_referrers_migrator'
class Referrer; end unless defined? Referrer

describe SiteReferrersMigrator do
  let(:site) { mock('Site', token: 'site_token') }
  let(:pages) { %w[url] }
  let(:migrator) { SiteReferrersMigrator.new(site) }

  describe "#migrate" do
    before {
      Referrer.stub(:last_urls) { pages }
      SiteAdminPagesMigratorWorker.stub(:perform_async)
    }

    it "gets last pages from Referrer" do
      Referrer.should_receive(:last_urls)
      migrator.migrate
    end

    it "delays migration to SiteAdminPagesMigratorWorker" do
      SiteAdminPagesMigratorWorker.should_receive(:perform_async).with(site.token, pages)
      migrator.migrate
    end
  end
end
