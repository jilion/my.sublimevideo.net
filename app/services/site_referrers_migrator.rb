require 'site_admin_pages_migrator_worker'

class SiteReferrersMigrator
  attr_accessor :site

  def initialize(site)
    @site = site
  end

  def migrate
    last_pages = Referrer.last_urls(site.token)
    SiteAdminPagesMigratorWorker.perform_async(site.token, last_pages)
  end
end
