# coding: utf-8
namespace :one_time do

  namespace :logs do
    desc "Reparse logs for site usages per day"
    task :reparse => :environment do
      timed do
        mixed_logs = Log.where(:started_at => { "$gte" => Date.new(2010, 10, 21).midnight, "$lte" => Time.parse("2010-10-21T08:09:00Z") })
        mixed_log_ids = mixed_logs.map(&:id)
        puts OneTime::Log.delay(:priority => 299).parse_logs(mixed_log_ids)
        puts "Delayed logs parsing for #{Date.new(2010, 10, 21).midnight} to #{Time.parse("2010-10-21T08:09:00Z")}."

        (Date.new(2010, 6, 30)..Date.new(2010, 10, 20)).each do |day|
          # comme ça on a les logs de S3 qui ont started_at => x et ended_at => x + 1.day
          full_days_logs = Log.where(:started_at => { "$gte" => day.midnight }, :ended_at => { "$lte" => (day + 1.day).midnight })
          log_ids = full_days_logs.map(&:id)
          puts OneTime::Log.delay(:priority => 300).parse_logs(log_ids)
          puts "Delayed reparsing of a batch of #{log_ids.size} logs collected on #{day}."
        end
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

    desc "Set remaining_discounted_months to all users"
    task :set_remaining_discounted_months => :environment do
      timed do
        puts OneTime::User.set_remaining_discounted_months + " beta users will get a discount"
      end
    end

    desc "Import all beta users to campaign monitor "
    task :import_all_beta_users_to_campaign_monitor => :environment do
      timed do
        OneTime::User.import_all_beta_users_to_campaign_monitor
      end
    end
  end

  namespace :sites do
    desc "Reset sites caches"
    task :reset_caches => :environment do
      Site.all.each { |site| site.delay(:priority => 400).reset_caches! }
    end

    desc "Update invalid sites move invalid dev hostnames into the extra_hostnames and remove dev hostnames that are duplication of main hostname"
    task :update_invalid_hostnames => :environment do
      timed do
        puts OneTime::Site.update_hostnames.join("\n")
      end
    end

    desc "Set all sites plan to the Beta plan"
    task :set_beta_plan => :environment do
      puts OneTime::Site.set_beta_plan
    end

    desc "Rollback all sites with the Beta plan to the Dev plan"
    task :rollback_beta_sites => :environment do
      puts OneTime::Site.rollback_beta_sites_to_dev
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
  end

end