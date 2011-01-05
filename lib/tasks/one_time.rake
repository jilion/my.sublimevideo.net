# coding: utf-8
namespace :one_time do
  
  namespace :logs do
    desc "Reparse logs for site usages per day"
    task :reparse => :environment do
      timed do
        mixed_logs = Log.where(:started_at => { "$gte" => Date.new(2010, 10, 21).beginning_of_day, "$lte" => Time.parse("2010-10-21T08:09:00Z") })
        mixed_log_ids = mixed_logs.map(&:id)
        puts OneTime::Log.delay(:priority => 299).parse_logs(mixed_log_ids)
        puts "Delayed logs parsing for #{Date.new(2010, 10, 21).beginning_of_day} to #{Time.parse("2010-10-21T08:09:00Z")}."
        
        (Date.new(2010, 6, 30)..Date.new(2010, 10, 20)).each do |day|
          # comme ça on a les logs de S3 qui ont started_at => x et ended_at => x + 1.day
          full_days_logs = Log.where(:started_at => { "$gte" => day.beginning_of_day }, :ended_at => { "$lte" => (day + 1.day).beginning_of_day })
          log_ids = full_days_logs.map(&:id)
          puts OneTime::Log.delay(:priority => 300).parse_logs(log_ids)
          puts "Delayed reparsing of a batch of #{log_ids.size} logs collected on #{day}."
        end
      end
    end
  end
  
  namespace :users do
    desc "Delete users that are invited but not yet registered, please check User.invited before !!!"
    task :delete_invited_not_yet_registered => :environment do
      timed do
        puts OneTime::User.delete_invited_not_yet_registered_users + " invited users deleted"
      end
    end
    
    desc "Set remaining_discounted_months to all users"
    task :set_remaining_discounted_months => :environment do
      timed do
        puts OneTime::User.set_remaining_discounted_months + " beta users will get a discount"
      end
    end
  end
  
  namespace :sites do
    desc "Reset sites caches"
    task :reset_caches => :environment do
      Site.all.each { |site| site.delay(:priority => 400).reset_caches! }
    end
    
    desc "Update invalid staff sites move invalid dev hostnames into the extra_hostnames and remove dev hostnames that are duplication of main hostname"
    task :update_staff_invalid_hostnames => :environment do
      timed do
        puts OneTime::Site.update_hostnames(true).join("\n")
      end
    end
    
    desc "Update invalid sites move invalid dev hostnames into the extra_hostnames and remove dev hostnames that are duplication of main hostname"
    task :update_invalid_hostnames => :environment do
      timed do
        puts OneTime::Site.update_hostnames(false).join("\n")
      end
    end
    
    desc "Set all staff sites state to 'beta'"
    task :set_staff_beta_state => :environment do
      puts OneTime::Site.set_beta_state(true)
    end
    
    desc "Set all sites state to 'beta'"
    task :set_beta_state => :environment do
      puts OneTime::Site.set_beta_state(false)
    end
    
    desc "Rollback all beta sites to 'dev' state"
    task :rollback_beta_sites => :environment do
      puts OneTime::Site.rollback_beta_sites_to_dev
    end
  end
  
end