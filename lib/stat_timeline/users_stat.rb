module StatTimeline

  class UsersStat
    attr_accessor :collection

    delegate :empty?, to: :collection

    def initialize(start_time, end_time, options = {})
      @start_time, @end_time = start_time, end_time
      @collection = ::Stats::UsersStat.between(@start_time.midnight, @end_time.end_of_day)
    end

    def timeline(attribute)
      (@start_time.to_date..@end_time.to_date).each_with_object([]) do |day, array|
        if users_stat = @collection.detect { |u| u.created_at >= day.midnight && u.created_at < day.end_of_day }
          array << users_stat.states_count[attribute.to_s]
        else
          array << 0
        end
      end
    end
  end
  
end
