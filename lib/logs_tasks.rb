module LogsTasks
  def self.parse_logs(log_ids)
    log_ids.each do |log_id|
      begin
        Log.delay(queue: 'my-logs').parse_log(log_id)
      rescue => ex
        Notifier.send("Error during the reparsing of Log ##{log_id}", exception: ex)
      end
    end
    "Delayed #{log_ids.size} individual logs."
  end

  def self.parse_logs_for_user_agents(log_ids)
    log_ids.each do |log_id|
      begin
        Log::Voxcast.delay(queue: 'my-logs').parse_log_for_user_agents(log_id)
      rescue => ex
        Notifier.send("Error during the reparsing of Log ##{log_id} for user agents", exception: ex)
      end
    end
    "Delayed #{log_ids.size} individual logs."
  end
end
