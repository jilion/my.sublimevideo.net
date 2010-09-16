module LogsFileFormat
  class VoxcastReferrers < RequestLogAnalyzer::FileFormat::Base
    extend LogsFileFormat::Voxcast
    
    def self.report_trackers
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      analyze.frequency(:referrer, :title => :referrers,
        :category => lambda { |r| [r[:referrer], player_token_from(r[:path])] },
        :if       => lambda { |r| player_token?(r[:path]) }
      )
      analyze.trackers
    end
    
  end
end