# encoding: utf-8

# http://cdn.sublimevideo.net/_.gif?t=ibvjcopp&i=1310389131519&h=m&e=l&vn=1
class VoxcastReferrersLogFileFormat < RequestLogAnalyzer::FileFormat::Base
  extend VoxcastLogFileFormat

  def self.report_trackers
    analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
    analyze.frequency(:referrer, title: :referrers,
      category: lambda { |r| [r[:referrer], token_from(r)] },
      if: lambda { |r| countable_hit?(r) && gif_request?(r) && page_load_event?(r) && good_token?(r) }
    )
    analyze.trackers
  end

end
