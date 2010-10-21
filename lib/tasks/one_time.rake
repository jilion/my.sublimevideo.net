# coding: utf-8
namespace :one_time do
  
  desc "Reparse logs for site usages per day"
  task :reparse_logs => :environment do
    timed do
      Log.where(:started_at => Time.parse("2010-10-21T08:09:00Z")).first
    end
  end
  
end