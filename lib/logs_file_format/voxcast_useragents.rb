module LogsFileFormat
  class VoxcastUseragents < RequestLogAnalyzer::FileFormat::Base
    extend LogsFileFormat::Voxcast

    def self.report_trackers
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      analyze.frequency(:useragent, :title => :useragent,
        :category => lambda { |r| [r[:useragent], player_token_from(r[:path])] },
        :if       => lambda { |r| player_token?(r[:path]) }
      )
      analyze.trackers
    end

  end
end