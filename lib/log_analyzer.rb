module LogAnalyzer
  class << self
    
    def parse
      ral = RequestLogAnalyzer::Controller.build(
        :format => LogsFileFormat::Voxcast,
        # :output => LogAnalyzer::Output,
        :boring => true,
        :silent => true,
        :source_files => Rails.root.join('spec/fixtures/*.gz').to_s
      )
      ral.aggregators.each { |agg| agg.prepare }
      ral.source.each_request do |request|
        ral.aggregate_request(ral.filter_request(request))
      end
      ral.aggregators.each { |agg| agg.finalize }
      ral.source.finalize
      
      p ral.source.parsed_lines
      p ral.source.skipped_lines
      ral.aggregators.first.trackers.each do |tracker|
        p tracker.options
        p tracker.categories
      end
    end
    
  end
end