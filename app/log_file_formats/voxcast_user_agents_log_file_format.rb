# encoding: utf-8
class VoxcastUserAgentsLogFileFormat < RequestLogAnalyzer::FileFormat::Base
  extend VoxcastLogFileFormat

  def self.report_trackers
    analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
    analyze.frequency(:useragent, title: :useragent,
      category: lambda { |r| [r[:useragent], token_from(r)] },
      if: lambda { |r| countable_hit?(r) && gif_request?(r) && page_load_event?(r) && good_token?(r) }
    )
    analyze.trackers
  end

end
