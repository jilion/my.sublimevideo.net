# coding: utf-8
namespace :one_time do

  namespace :logs do
    desc "Reparse logs for site usages"
    task :reparse => :environment do
      timed do
        beginning_of_month = Time.now.utc.beginning_of_month
        SiteUsage.where(:day => { "$gte" => beginning_of_month }).delete_all

        months_logs = Log.where(:started_at => { "$gte" => beginning_of_month })
        months_logs_ids = months_logs.map(&:id)
        puts OneTime::Log.delay(:priority => 299).parse_logs(months_logs_ids)
        puts "Delayed logs parsing from #{beginning_of_month}"
      end
    end

    desc "Reparse voxcast logs for user agent"
    task :reparse => :environment do
      timed do
        beginning_of_month = Time.now.utc.beginning_of_month
        UsrAgent.where(:month => { "$gte" => beginning_of_month }).delete_all

        months_logs = Log::Voxcast.where(:started_at => { "$gte" => beginning_of_month })
        months_logs_ids = months_logs.map(&:id)
        puts OneTime::Log.delay(:priority => 299).parse_logs_for_user_agents(months_logs_ids)
        puts "Delayed Voxcast logs parsing for user agent from #{beginning_of_month}"
      end
    end
  end

  namespace :users do
    desc "Archive users that are invited but not yet registered, please check User.invited before !!!"
    task :archive_invited_not_yet_registered => :environment do
      timed do
        puts OneTime::User.archive_invited_not_yet_registered_users + " invited users deleted"
      end
    end

    desc "Import all beta users to campaign monitor "
    task :import_all_beta_users_to_campaign_monitor => :environment do
      timed do
        OneTime::User.import_all_beta_users_to_campaign_monitor
      end
    end

    desc "Set a unique cc_alias for all users that don't have one yet"
    task :uniquify_all_empty_cc_alias => :environment do
      timed do
        OneTime::User.uniquify_all_empty_cc_alias
      end
    end
  end

  namespace :sites do
    desc "Set all sites plan to the Beta plan"
    task :set_beta_plan => :environment do
      puts OneTime::Site.set_beta_plan
    end

    desc "Set plan_started_at"
    task :set_plan_started_at => :environment do
      puts OneTime::Site.set_plan_started_at
    end

    desc "Update invalid sites move invalid dev hostnames into the extra_hostnames and remove dev hostnames that are duplication of main hostname"
    task :update_invalid_hostnames => :environment do
      timed do
        puts OneTime::Site.update_hostnames.join("\n")
      end
    end

    desc "Rollback all sites with the Beta plan to the Dev plan"
    task :rollback_beta_sites => :environment do
      puts OneTime::Site.rollback_beta_sites_to_dev
    end

    desc "Reset sites caches"
    task :reset_caches => :environment do
      Site.all.each { |site| site.delay(:priority => 400).reset_caches! }
    end

    desc "Parse all unparsed user_agents logs"
    task :parse_user_agents_logs => :environment do
      count = Log::Voxcast.where(:user_agents_parsed_at => nil).count
      skip  = 0
      while skip < count
        ids = Log::Voxcast.where(:user_agents_parsed_at => nil).only(:id).limit(1000).skip(skip).map(&:id)
        ids.each { |id| Log::Voxcast.delay(:priority => 90, :run_at => 1.minute.from_now).parse_log_for_user_agents(id) }
        skip += 1000
      end
    end

    desc "Re-generate loader and license templates for all sites"
    task :regenerate_all_loaders_and_licenses => :environment do
      puts OneTime::Site.regenerate_all_loaders_and_licenses
    end
  end

  namespace :plans do
    desc "Create all plans"
    task :create_plans => :environment do
      puts OneTime::Plan.create_plans
    end
  end

end