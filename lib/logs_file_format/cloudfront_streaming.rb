module LogsFileFormat
  class CloudfrontStreaming < RequestLogAnalyzer::FileFormat::Base
    extend RequestLogAnalyzer::FileFormat::CommonRegularExpressions
    extend LogsFileFormat::Amazon
    
    LINE_DEFINITIONS = [
      #Fields: date time x-edge-location c-ip x-event sc-bytes x-cf-status x-cf-client-id cs-uri-stem cs-uri-query c-referrer x-page-url c-user-agent x-sname x-sname-query x-file-ext x-sid
      { :regexp => "(#{timestamp('%Y-%m-%d')})", :captures => [{:name => :date,          :type => :timestamp}] },
      { :regexp => "(#{timestamp('%H:%M:%S')})", :captures => [{:name => :time,          :type => :timestamp}] },
      { :regexp => '(.*)',                       :captures => [{:name => :edge_location, :type => :string}] },
      { :regexp => "(#{ip_address})",            :captures => [{:name => :client_ip,     :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :event,         :type => :string}] },
      { :regexp => '(\d+|-)',                    :captures => [{:name => :sc_bytes,      :type => :traffic}] },
      { :regexp => '(.*)',                       :captures => [{:name => :cf_status,     :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :cf_client_id,  :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :uri_stem,      :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :uri_query,     :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :referer,       :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :page_url,      :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :user_agent,    :type => :string}] },
      # The following fields are present only on Play, Stop, Pause, Unpause, and Seek events. For other events, these fields will contain a single dash (-).
      { :regexp => '(.*)',                       :captures => [{:name => :sname,         :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :sname_query,   :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :file_ext,      :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :sid,           :type => :string}] }
    ]
    
    def self.create(*args)
      self.new({:default => line_definition}, report_trackers)
    end
    
    def self.line_definition
      regexps, captures = [], []
      
      LINE_DEFINITIONS.each do |definition|
        regexps  << definition[:regexp]
        captures += definition[:captures]
      end
      
      RequestLogAnalyzer::LineDefinition.new(
        :default,
        :regexp => Regexp.new(regexps.join('\t')),
        :captures => captures,
        :header => true,
        :footer => true
      )
    end
    
    def self.report_trackers
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      analyze.frequency(:sname, :title => :hits,
        :category => lambda { |r| video_token_from(r[:sname]) },
        :if       => lambda { |r| r[:event] == "stop" && video_token?(r[:sname]) && video_key?(r[:sname]) }
      )
      analyze.traffic(:sc_bytes, :title => :traffic_us,
        :category => lambda { |r| video_token_from(r[:sname]) },
        :if       => lambda { |r| r[:event] == "stop" && video_token?(r[:sname]) && us_location?(r[:edge_location]) }
      )
      analyze.traffic(:sc_bytes, :title => :traffic_eu,
        :category => lambda { |r| video_token_from(r[:sname]) },
        :if       => lambda { |r| r[:event] == "stop" && video_token?(r[:sname]) && eu_location?(r[:edge_location]) }
      )
      analyze.traffic(:sc_bytes, :title => :traffic_as,
        :category => lambda { |r| video_token_from(r[:sname]) },
        :if       => lambda { |r| r[:event] == "stop" && video_token?(r[:sname]) && as_location?(r[:edge_location]) }
      )
      analyze.traffic(:sc_bytes, :title => :traffic_jp,
        :category => lambda { |r| video_token_from(r[:sname]) },
        :if       => lambda { |r| r[:event] == "stop" && video_token?(r[:sname]) && jp_location?(r[:edge_location]) }
      )
      analyze.traffic(:sc_bytes, :title => :traffic_unknown,
        :category => lambda { |r| video_token_from(r[:sname]) },
        :if       => lambda { |r| r[:event] == "stop" && video_token?(r[:sname]) && unknown_location?(r[:edge_location]) }
      )
      # analyze.frequency(:sname, :title => :requests_us,
      #   :category => lambda { |r| video_token_from(r[:sname]) },
      #   :if       => lambda { |r| video_token?(r[:sname]) && us_location?(r[:edge_location]) }
      # )
      # analyze.frequency(:sname, :title => :requests_eu,
      #   :category => lambda { |r| video_token_from(r[:sname]) },
      #   :if       => lambda { |r| video_token?(r[:sname]) && eu_location?(r[:edge_location]) }
      # )
      # analyze.frequency(:sname, :title => :requests_as,
      #   :category => lambda { |r| video_token_from(r[:sname]) },
      #   :if       => lambda { |r| video_token?(r[:sname]) && as_location?(r[:edge_location]) }
      # )
      # analyze.frequency(:sname, :title => :requests_jp,
      #   :category => lambda { |r| video_token_from(r[:sname]) },
      #   :if       => lambda { |r| video_token?(r[:sname]) && jp_location?(r[:edge_location]) }
      # )
      # analyze.frequency(:sname, :title => :requests_unknown,
      #   :category => lambda { |r| video_token_from(r[:sname]) },
      #   :if       => lambda { |r| video_token?(r[:sname]) && unknown_location?(r[:edge_location]) }
      # )
      analyze.trackers
    end
    
  end
end