module OneTime
  module Log
    
    class << self
      
      def parse_logs(log_ids)
        log_ids.each do |log_id|
          begin
            Log.delay(:priority => 200).parse_log(log_id)
          rescue => ex
            Notify.send("Error during the reparsing of Log ##{log_id}", :exception => ex)
          end
        end
        "Delayed #{log_ids.size} individual logs."
      end
      
    end
    
  end
end