module Analytics
  module SeriesBuilder
    module Distribution
      mattr_accessor :series, :labels_array
      
      def self.series_and_labels(series_array)
        @series           = {}
        @labels_array     = []
        @datalabels_array = {}
        
        populate_series(series_array)
        
        [@series, @labels_array, @datalabels_array]
      end
      
    private
      
      def self.populate_series(series_array)
        series_array.each do |serie_array|
          serie_array[1].each do |serie_values_array|
            (@series[serie_array[1].index(serie_values_array)] ||= []) << serie_values_array[1]
            (@datalabels_array[serie_array[1].index(serie_values_array)] ||= []) << "#{serie_values_array[0].to_s.titleize}: #{serie_values_array[1]}"
          end
          @labels_array << serie_array[0].to_s.titleize
        end
      end
      
    end
  end
end