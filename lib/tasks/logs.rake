require 'logs_tasks'

namespace :logs do
  desc "Reparse logs for site usages"
  task reparse: :environment do
    timed do
      beginning_of_month = Time.now.utc.beginning_of_month
      SiteUsage.where(day: { :$gte => beginning_of_month }).delete_all

      months_logs = Log.where(started_at: { :$gte => beginning_of_month })
      months_logs_ids = months_logs.map(&:id)
      puts LogsTasks.delay(queue: 'log').parse_logs(months_logs_ids)
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
      puts LogsTasks.delay(queue: 'log').parse_logs_for_user_agents(months_logs_ids)
      puts "Delayed Voxcast logs parsing for user agent from #{beginning_of_month}"
    end
  end

  task parse_unparsed_logs: :environment do
    count = Log::Voxcast.where(parsed_at: nil).count
    skip  = 0
    while skip < count
      ids = Log::Voxcast.where(parsed_at: nil).only(:id).limit(1000).skip(skip).map(&:id)
      ids.each { |id| Log.delay(queue: 'log').parse_log(id) }
      skip += 1000
    end
  end

  task search_for_missing_voxcast_logs: :environment do
    VoxcastWrapper.logs_list(VoxcastWrapper.hostname).each do |log|
      log_name = log['content']
      unless Log::Voxcast.where(name: log_name).exists?
        Log::Voxcast.delay.safely_create(name: log_name)
        puts "#{log_name} was missing."
      end
    end
  end
end
