require 'sites_tasks'

namespace :sites do
  desc "Reset sites caches"
  task reset_caches: :environment do
    timed { Site.all.each { |site| site.delay(queue: 'my-low').reset_caches! } }
  end

  desc "Re-generate loaders templates for all sites"
  task regenerate_loaders: :environment do
    timed { puts SitesTasks.regenerate_templates(loaders: true, settings: false) }
  end

  desc "FAST Re-generate loaders templates for all sites"
  task fast_regenerate_loaders: :environment do
    timed { puts SitesTasks.regenerate_templates(fast: true, loaders: true, settings: false) }
  end

  desc "Re-generate settings templates for all sites"
  task regenerate_settings: :environment do
    timed { puts SitesTasks.regenerate_templates(loaders: false, settings: true) }
  end

  desc "Re-generate loaders and settings templates for all sites"
  task regenerate_loaders_and_settings: :environment do
    timed { puts SitesTasks.regenerate_templates(loaders: true, settings: true) }
  end

  desc "Exit beta"
  task exit_beta: :environment do
    timed { puts SitesTasks.exit_beta }
  end
end
