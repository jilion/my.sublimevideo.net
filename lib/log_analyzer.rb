module LogAnalyzer
  class << self
    
    # Return just RequestLogAnalyzer trackers
    def parse(logs_file)
      @controller = RequestLogAnalyzer::Controller.build(
        :format => LogsFileFormat::Voxcast,
        :boring => true,
        :silent => true,
        :source_files => logs_file.path
      )
      run!
      @controller.aggregators.first.trackers
    end
    
  private
    
    def run!
      @controller.aggregators.each { |agg| agg.prepare }
      @controller.source.each_request do |request|
        @controller.aggregate_request(@controller.filter_request(request))
      end
      @controller.aggregators.each { |agg| agg.finalize }
      @controller.source.finalize
      
      notify_skipped_lines
    end
    
    def notify_skipped_lines
      if @controller.source.skipped_lines > 0
        # TODO Notify via Exceptional
      end
    end
    
  end
end