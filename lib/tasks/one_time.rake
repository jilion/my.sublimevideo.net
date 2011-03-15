# coding: utf-8
namespace :one_time do

  desc "Reparse logs for site usages per day"
  task :reparse_logs => :environment do
    timed do
      mixed_logs = Log.where(:started_at => { "$gte" => Date.new(2010, 10, 21).beginning_of_day, "$lte" => Time.parse("2010-10-21T08:09:00Z") })
      mixed_log_ids = mixed_logs.map(&:id)
      Log.delay(:priority => 299).parse_logs(mixed_log_ids)
      puts "Delayed logs parsing for #{Date.new(2010, 10, 21).beginning_of_day} to #{Time.parse("2010-10-21T08:09:00Z")}."

      (Date.new(2010, 6, 30)..Date.new(2010, 10, 20)).each do |day|
        # comme ça on a les logs de S3 qui ont started_at => x et ended_at => x + 1.day
        full_days_logs = Log.where(:started_at => { "$gte" => day.beginning_of_day }, :ended_at => { "$lte" => (day + 1.day).beginning_of_day })
        log_ids = full_days_logs.map(&:id)
        Log.delay(:priority => 300).parse_logs(log_ids)
        puts "Delayed reparsing of a batch of #{log_ids.size} logs collected on #{day}."
      end
    end
  end

  desc "Reset sites caches"
  task :reset_sites_caches => :environment do
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

end

class Log
  def self.parse_logs(log_ids)
    log_ids.each do |log_id|
      begin
        Log.delay(:priority => 200).parse_log(log_id)
      rescue => ex
        Notify.send("Error during the reparsing of Log ##{log_id}", :exception => ex)
      end
    end
    puts "Delayed #{log_ids.size} individual logs."
  end
end