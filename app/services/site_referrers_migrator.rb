require 'site_admin_pages_migrator_worker'

class SiteReferrersMigrator
  attr_accessor :site

  def self.migrate_all
    Site.all.each { |site| self.delay(queue: 'my-stats_migration').migrate(site.id) }
  end

  def self.migrate(site_id)
    site = Site.find_by_id(site_id)
    new(site).migrate
  end

  def initialize(site)
    @site = site
  end

  def migrate
    last_pages = Referrer.last_urls(site.token)
    SiteAdminPagesMigratorWorker.perform_async(site.token, last_pages)
  end
end
