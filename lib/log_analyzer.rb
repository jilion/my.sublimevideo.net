# encoding: utf-8
require_dependency 'notify'
require_dependency 'logs_file_format'

module LogAnalyzer
  class << self

    # Return just RequestLogAnalyzer trackers
    def parse(log_file, file_format_class_name)
      @controller = RequestLogAnalyzer::Controller.build(
        format: file_format_class_name.constantize,
        boring: true,
        silent: true,
        source_files: log_file.path
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
        Notify.send("LogAnalyzer skipped #{@controller.source.skipped_lines} line(s) for #{@controller.source.source_files}")
      end
    end

  end
end