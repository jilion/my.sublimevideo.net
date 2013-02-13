# encoding: utf-8
class LogAnalyzer

  # Return just RequestLogAnalyzer trackers
  def self.parse(log_file, file_format_class_name)
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

  def self.run!
    @controller.aggregators.each { |agg| agg.prepare }
    @controller.source.each_request do |request|
      @controller.aggregate_request(@controller.filter_request(request))
    end
    @controller.aggregators.each { |agg| agg.finalize }
    @controller.source.finalize

    notify_skipped_lines
  end

  def self.notify_skipped_lines
    if @controller.source.skipped_lines > 0
      Notifier.send("LogAnalyzer skipped #{@controller.source.skipped_lines} line(s) for #{@controller.source.source_files}")
    end
  end
end
