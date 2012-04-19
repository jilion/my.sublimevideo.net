# encoding: utf-8 

module LogsFileFormat
  class VoxcastSites < RequestLogAnalyzer::FileFormat::Base
    extend LogsFileFormat::Voxcast

    def self.report_trackers
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      analyze.traffic(:response_bytes, :title => :traffic_voxcast,
        :category => lambda { |r| token_from(r) },
        :if       => lambda { |r| token?(r) }
      )
      analyze.frequency(:path, :title => :loader_hits,
        :category => lambda { |r| [loader_token_from(r), r[:referrer]] },
        :if       => lambda { |r| loader_token?(r) && countable_hit?(r) }
      )
      analyze.frequency(:path, :title => :player_hits,
        :category => lambda { |r| [player_token_from(r), r[:http_status], r[:referrer]] },
        :if       => lambda { |r| player_token?(r) && countable_hit?(r) }
      )
      analyze.frequency(:path, :title => :flash_hits,
        :category => lambda { |r| flash_token_from(r) },
        :if       => lambda { |r| flash_token?(r) && countable_hit?(r) }
      )
      analyze.trackers
    end

  end
end
