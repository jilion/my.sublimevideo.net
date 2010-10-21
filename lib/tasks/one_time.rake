# coding: utf-8
namespace :one_time do
  
  desc "Reparse logs for site usages per day"
  task :reparse_logs => :environment do
    timed do
      mixed_logs = Log.where(:started_at => { "$gte" => Date.new(2010, 10, 21).beginning_of_day, "$lte" => Time.parse("2010-10-21T08:09:00Z") })
      Log.delay(:priority => 200).parse_logs(mixed_logs)
      puts "Delayed logs parsing for #{Date.new(2010, 10, 21).beginning_of_day} to #{Time.parse("2010-10-21T08:09:00Z")}."
      
      (Date.new(2010, 6, 30)..Date.new(2010, 10, 20)).each do |day|
        full_day_logs = Log.where(:started_at => { "$gte" => day.beginning_of_day }, :ended_at => { "$lte" => (day + 1.day).beginning_of_day })
        # Log.delay(:priority => 200).parse_logs(full_day_logs)
        puts "Delayed logs parsing for #{day}."
      end
    end
  end
  
end

class Log
  def self.parse_logs(logs)
    logs.each do |log|
      # log.delay(:priority => 200).parse_and_create_usages!
      puts "Delayed log parsing for #{log.started_at}."
    end
  end
end