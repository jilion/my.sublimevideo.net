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
        puts OneTime::Log.delay(queue: 'low').parse_logs(months_logs_ids)
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
        puts OneTime::Log.delay(queue: 'low').parse_logs_for_user_agents(months_logs_ids)
        puts "Delayed Voxcast logs parsing for user agent from #{beginning_of_month}"
      end
    end

    task parse_unparsed_logs: :environment do
      count = Log::Voxcast.where(parsed_at: nil).count
      skip  = 0
      while skip < count
        ids = Log::Voxcast.where(parsed_at: nil).only(:id).limit(1000).skip(skip).map(&:id)
        ids.each { |id| Log.delay(queue: 'low').parse_log(id) }
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
    desc "Update billable custom field on Campaign Monitor for all active users"
    task update_campaign_monitor_billable_custom_field_for_all_active_users: :environment do
      timed { OneTime::User.update_campaign_monitor_billable_custom_field_for_all_active_users }
    end
  end

  namespace :plans do
  end

  namespace :video_tags do
    desc "Update video_tags name"
    task update_names: :environment do
      timed { OneTime::VideoTag.update_names }
    end
  end

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
        ids.each { |id| Log::Voxcast.delay(queue: 'low', at: 1.minute.from_now.to_i).parse_log_for_user_agents(id) }
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

    # NEW ADDONS BUSINESS MODEL TASKS

    # STEP 1
    desc "Step 1: db:migrate, one_time:sites:set_default_domain, one_time:sites:update_accessible_stage, db:populate:addons"
    task migration_step_1: :environment do
      Rake::Task['db:migrate'].execute
      Rake::Task['one_time:sites:set_default_domain'].execute
      Rake::Task['one_time:sites:update_accessible_stage'].execute
      Rake::Task['db:populate:addons'].execute
    end

    desc "Set default domain name to all sites without a domain name set"
    task set_default_domain: :environment do
      timed { Site.where(hostname: ['', nil]).update_all(hostname: Site::DEFAULT_DOMAIN) }
    end

    desc "For all non-archived sites, update accessible_stage"
    task update_accessible_stage: :environment do
      timed { puts OneTime::Site.update_accessible_stage }
    end

    # STEP 2
    desc "Step 2: one_time:sites:move_staging_hostnames_from_extra, one_time:sites:add_already_paid_amount_to_balance_for_monthly_plans, one_time:sites:migrate_yearly_plans_to_monthly_plans, one_time:sites:create_default_kit_for_all_non_archived_sites, one_time:sites:create_preview_kits"
    task migration_step_2: :environment do
      Rake::Task['one_time:sites:move_staging_hostnames_from_extra'].execute
      Rake::Task['one_time:sites:add_already_paid_amount_to_balance_for_monthly_plans'].execute
      Rake::Task['one_time:sites:migrate_yearly_plans_to_monthly_plans'].execute
      Rake::Task['one_time:sites:create_default_kit_for_all_non_archived_sites'].execute
      Rake::Task['one_time:sites:create_preview_kits'].execute
    end

    desc "For all non-archived site, extracts staging hostnames from extra domains"
    task move_staging_hostnames_from_extra: :environment do
      timed { puts OneTime::Site.move_staging_hostnames_from_extra }
    end

    desc "For all non-archived site with a monthly plan, add the plan's price prorated between [now] and the end of the site's cycle and add it to the user's balance"
    task add_already_paid_amount_to_balance_for_monthly_plans: :environment do
      timed { puts OneTime::Site.add_already_paid_amount_to_balance_for_monthly_plans }
    end

    desc "Change non-archived sites with yearly plan to the monthly cycle and add the plan's price prorated between [now] and the end of the site's cycle and add it to the user's balance"
    task migrate_yearly_plans_to_monthly_plans: :environment do
      timed { puts OneTime::Site.migrate_yearly_plans_to_monthly_plans }
    end

    desc "For all non-archived sites, create a default kit"
    task create_default_kit_for_all_non_archived_sites: :environment do
      timed { puts OneTime::Site.create_default_kit_for_all_non_archived_sites }
    end

    desc "Create the preview kits for my.sublimevideo.net"
    task create_preview_kits: :environment do
      timed { puts OneTime::Site.create_preview_kits }
    end

    # STEP 3
    desc "Step 3: one_time:sites:migrate_plans_to_addons"
    task migration_step_3: :environment do
      Rake::Task['one_time:sites:migrate_plans_to_addons'].execute
    end

    desc "For all non-archived sites, migrate from the old plans to the new add-ons business model"
    task migrate_plans_to_addons: :environment do
      timed { puts OneTime::Site.migrate_plans_to_addons }
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
