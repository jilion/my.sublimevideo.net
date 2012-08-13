# encoding: utf-8

module LogsFileFormat
  class VoxcastUserAgents < RequestLogAnalyzer::FileFormat::Base
    extend LogsFileFormat::Voxcast

    def self.report_trackers
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      analyze.frequency(:useragent, title: :useragent,
        category: lambda { |r| [r[:useragent], token_from(r)] },
        if: lambda { |r| countable_hit?(r) && gif_request?(r) && page_load_event?(r) && good_token?(r) }
      )
      analyze.trackers
    end

  end
end
