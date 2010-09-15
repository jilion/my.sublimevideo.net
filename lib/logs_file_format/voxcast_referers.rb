module LogsFileFormat
  class VoxcastReferers < RequestLogAnalyzer::FileFormat::Base
    extend LogsFileFormat::Voxcast
    
    def self.report_trackers
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      analyze.frequency(:referer, :title => :referers,
        :category => lambda { |r| [r[:referer], player_token_from(r[:path])] },
        :if       => lambda { |r| player_token?(r[:path]) }
      )
      analyze.trackers
    end
    
  end
end