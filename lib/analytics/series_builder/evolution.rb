module Analytics
  module SeriesBuilder
    module Evolution
      mattr_accessor :start_time, :end_time, :render_engine, :series, :labels_array
      
      def self.series_and_labels(series_hash, start_time, end_time, render_engine = "grafico")
        @start_time    = start_time
        @end_time      = end_time
        @render_engine = render_engine
        @series = {}
        
        populate_series(series_hash[:per_day], false) if series_hash[:per_day]
        populate_series(series_hash[:total], true) if series_hash[:total]
        [@series, @labels_array]
      end
      
    private
      
      def self.populate_series(hash, total)
        @series.merge!(hash.inject({}) do |memo, serie_hash|
          if serie_hash[1].is_a?(Array)
            base_scoped_query = serie_hash[1][0]
            date_field = serie_hash[1][1] if serie_hash[1].size == 2
          end
          data, labels = populate_serie(base_scoped_query || serie_hash[1], date_field || :created_at, total)
          memo[serie_hash[0]] = data
          @labels_array = labels unless @labels_array
          memo
        end)
      end
      
      def self.populate_serie(base_scoped_query, date_field, total)
        total_sum = base_scoped_query.where(date_field.to_sym.lte => @start_time).count if total
        results_by_day = base_scoped_query.select("date(#{date_field}) as #{date_field}, count(*) as total").
                         where(date_field.to_sym => @start_time..@end_time).group("date(#{date_field})")
        # results_by_day = base_scoped_query.select("date_trunc('hour', #{date_field}) as #{date_field}, count(*) as total").
        #                  where(date_field.to_sym => @start_time..@end_time).group("date_trunc('hour', #{date_field})")
                         
        labels = []
        data = (@start_time.to_date..@end_time.to_date).inject([]) do |memo, date|
          date_time = DateTime.civil(date.year, date.month, date.day)
          # (0..23).each do |hour|
            result = results_by_day.detect { |result| result.send(date_field).to_date == date }
            # result = results_by_day.detect { |result| result.send(date_field).to_date == date && result.send(date_field).hour == hour }
            count = result ? result.total.to_i : 0
            if total
              total_sum += count
              count = total_sum
            end
            
            case @render_engine
            when "grafico"
              memo << count
              labels << date.strftime("%b %d")#date.strftime("%d/%m")
              # labels << date_time.change(:hour => hour).strftime("%d/%m %H:%M")
            when "flotr"
              memo << [date.to_time.to_i*1000, count]
            end
          # end
          memo
        end
        [data, labels]
      end
      
    end
  end
end