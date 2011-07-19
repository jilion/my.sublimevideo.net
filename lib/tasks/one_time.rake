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
    task :reparse_user_agent => :environment do
      timed do
        beginning_of_month = Time.now.utc.beginning_of_month
        UsrAgent.where(:month => { "$gte" => beginning_of_month }).delete_all

        months_logs = Log::Voxcast.where(:started_at => { "$gte" => beginning_of_month })
        months_logs_ids = months_logs.map(&:id)
        puts OneTime::Log.delay(:priority => 299).parse_logs_for_user_agents(months_logs_ids)
        puts "Delayed Voxcast logs parsing for user agent from #{beginning_of_month}"
      end
    end

    task :parse_unparsed_logs => :environment do
      count = Log::Voxcast.where(:parsed_at => nil).count
      skip  = 0
      while skip < count
        ids = Log::Voxcast.where(:parsed_at => nil).only(:id).limit(1000).skip(skip).map(&:id)
        ids.each { |id| Log.delay(:priority => 100).parse_log(id) }
        skip += 1000
      end
    end
  end

  namespace :users do
  end

  namespace :sites do
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

    desc "Move local ip from hostname and extra hostnames to dev domains for all sites"
    task :move_local_ip_from_hostname_and_extra_domains_to_dev_domains => :environment do
      puts OneTime::Site.move_local_ip_from_hostname_and_extra_domains_to_dev_domains
    end
  end

end