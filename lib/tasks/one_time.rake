# coding: utf-8
require_dependency 'public_launch'

namespace :one_time do

  namespace :logs do
    desc "Reparse logs for site usages"
    task reparse: :environment do
      timed do
        beginning_of_month = Time.now.utc.beginning_of_month
        SiteUsage.where(day: { :$gte => beginning_of_month }).delete_all

        months_logs = Log.where(started_at: { :$gte => beginning_of_month })
        months_logs_ids = months_logs.map(&:id)
        puts OneTime::Log.delay(priority: 299).parse_logs(months_logs_ids)
        puts "Delayed logs parsing from #{beginning_of_month}"
      end
    end

    desc "Reparse voxcast logs for user agent"
    task reparse_user_agent: :environment do
      timed do
        beginning_of_month = Time.now.utc.beginning_of_month
        UsrAgent.where(month: { :$gte => beginning_of_month }).delete_all

        months_logs = Log::Voxcast.where(started_at: { :$gte => beginning_of_month })
        months_logs_ids = months_logs.map(&:id)
        puts OneTime::Log.delay(priority: 299).parse_logs_for_user_agents(months_logs_ids)
        puts "Delayed Voxcast logs parsing for user agent from #{beginning_of_month}"
      end
    end

    task parse_unparsed_logs: :environment do
      count = Log::Voxcast.where(parsed_at: nil).count
      skip  = 0
      while skip < count
        ids = Log::Voxcast.where(parsed_at: nil).only(:id).limit(1000).skip(skip).map(&:id)
        ids.each { |id| Log.delay(priority: 100).parse_log(id) }
        skip += 1000
      end
    end

    task search_for_missing_voxcast_logs: :environment do
      [CDN::VoxcastWrapper.non_ssl_hostname, CDN::VoxcastWrapper.ssl_hostname].each do |hostname|
        puts "Logs for #{hostname}:"
        CDN::VoxcastWrapper.logs_list(hostname).each do |log|
          log_name = log['content']
          unless Log::Voxcast.where(name: log_name).exists?
            Log::Voxcast.delay.safely_create(name: log_name)
            puts "#{log_name} was missing."
          end
        end
      end
    end
  end

  namespace :users do
  end

  namespace :plans do
  end

  namespace :video_tags do
  end

  namespace :sites do
    desc "Reset sites caches"
    task reset_caches: :environment do
      timed { Site.all.each { |site| site.delay(priority: 400).reset_caches! } }
    end

    desc "Parse all unparsed user_agents logs"
    task parse_user_agents_logs: :environment do
      count = Log::Voxcast.where(user_agents_parsed_at: nil).count
      skip  = 0
      while skip < count
        ids = Log::Voxcast.where(user_agents_parsed_at: nil).only(:id).limit(1000).skip(skip).map(&:id)
        ids.each { |id| Log::Voxcast.delay(priority: 90, run_at: 1.minute.from_now).parse_log_for_user_agents(id) }
        skip += 1000
      end
    end

    desc "Re-generate loaders templates for all sites"
    task regenerate_loaders: :environment do
      timed { puts OneTime::Site.regenerate_templates(loaders: true, settings: false) }
    end

    desc "Re-generate settings templates for all sites"
    task regenerate_settings: :environment do
      timed { puts OneTime::Site.regenerate_templates(loaders: false, settings: true) }
    end

    desc "Re-generate loaders and settings templates for all sites"
    task regenerate_loaders_and_settings: :environment do
      timed { puts OneTime::Site.regenerate_templates(loaders: true, settings: true) }
    end

    desc "Update last 30 days counters of all not archived sites"
    task update_last_30_days_counters_for_not_archived_sites: :environment do
      timed { Site.update_last_30_days_counters_for_not_archived_sites }
    end

    desc "Set first_billable_plays_at for all sites that already had more than 10 views / day"
    task set_first_billable_plays_at_for_not_archived_sites: :environment do
      timed { Site.set_first_billable_plays_at_for_not_archived_sites }
    end

    desc "Update sites currently in trial to the new 'real' trial plan"
    task update_sites_in_trial_to_new_trial_plan: :environment do
      timed { puts OneTime::Site.update_sites_in_trial_to_new_trial_plan }
    end
  end

  namespace :stats do

    desc "Reduce stats trial hash into a fixnum"
    task reduce_trial_hash: :environment do
      timed do
        puts ::OneTime::Stats::SitesStat.reduce_trial_hash
      end
    end
  end
end
