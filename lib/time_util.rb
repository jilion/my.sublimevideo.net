module TimeUtil

  class << self

    def full_month(time = Time.now.utc)
      [time.beginning_of_month, time.end_of_month]
    end
    alias :current_month :full_month

    def prev_full_month(time = Time.now.utc)
      [time.prev_month.beginning_of_month, time.prev_month.end_of_month]
    end

    def next_full_month(time = Time.now.utc)
      [time.next_month.beginning_of_month, time.next_month.end_of_month]
    end

  end

end
