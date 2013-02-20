require 'sites_tasks'

namespace :sites do
  desc "Reset sites caches"
  task reset_caches: :environment do
    timed { Site.all.each { |site| site.delay(queue: 'low').reset_caches! } }
  end

  desc "Parse all unparsed user_agents logs"
  task parse_user_agents_logs: :environment do
    count = Log::Voxcast.where(user_agents_parsed_at: nil).count
    skip  = 0
    while skip < count
      ids = Log::Voxcast.where(user_agents_parsed_at: nil).only(:id).limit(1000).skip(skip).map(&:id)
      ids.each { |id| Log::Voxcast.delay(queue: 'log', at: 1.minute.from_now.to_i).parse_log_for_user_agents(id) }
      skip += 1000
    end
  end

  desc "Re-generate loaders templates for all sites"
  task regenerate_loaders: :environment do
    timed { puts SitesTasks.regenerate_templates(loaders: true, settings: false) }
  end

  desc "Re-generate settings templates for all sites"
  task regenerate_settings: :environment do
    timed { puts SitesTasks.regenerate_templates(loaders: false, settings: true) }
  end

  desc "Re-generate loaders and settings templates for all sites"
  task regenerate_loaders_and_settings: :environment do
    timed { puts SitesTasks.regenerate_templates(loaders: true, settings: true) }
  end

  desc "Update last 30 days counters of all not archived sites"
  task update_last_30_days_counters_for_not_archived_sites: :environment do
    timed { Site.update_last_30_days_counters_for_not_archived_sites }
  end

  desc "Exit beta"
  task exit_beta: :environment do
    timed { puts SitesTasks.exit_beta }
  end
end
