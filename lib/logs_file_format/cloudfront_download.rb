module LogsFileFormat
  class CloudfrontDownload < RequestLogAnalyzer::FileFormat::Base
    extend RequestLogAnalyzer::FileFormat::CommonRegularExpressions
    extend LogsFileFormat::Amazon
    
    LINE_DEFINITIONS = [
      { :regexp => "(#{timestamp('%Y-%m-%d')})", :captures => [{:name => :date,          :type => :timestamp}] },
      { :regexp => "(#{timestamp('%H:%M:%S')})", :captures => [{:name => :time,          :type => :timestamp}] },
      { :regexp => '(.*)',                       :captures => [{:name => :edge_location, :type => :string}] },
      { :regexp => '(\d+|-)',                    :captures => [{:name => :sc_bytes,      :type => :traffic}] },
      { :regexp => "(#{ip_address})",            :captures => [{:name => :client_ip,     :type => :string}] },
      { :regexp => '(\S+)',                      :captures => [{:name => :http_method,   :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :host,          :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :path,          :type => :string}] },
      { :regexp => '(\d{3})',                    :captures => [{:name => :http_status,   :type => :integer}] },
      { :regexp => '(.*)',                       :captures => [{:name => :referer,       :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :user_agent,    :type => :string}] },
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
      @ips = []
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      analyze.frequency(:path, :title => :hits,
        :category  => lambda { |r| video_token_from(r[:path]) },
        :if        => lambda { |r| video_key?(r[:path]) && video_token?(r[:path]) && @ips.exclude?("#{r[:client_ip]}/#{video_token_from(r[:path])}") && @ips << "#{r[:client_ip]}/#{video_token_from(r[:path])}" }
      )
      analyze.traffic(:sc_bytes, :title => :traffic_us,
        :category => lambda { |r| video_token_from(r[:path]) },
        :if       => lambda { |r| video_token?(r[:path]) && us_location?(r[:edge_location]) }
      )
      analyze.traffic(:sc_bytes, :title => :traffic_eu,
        :category => lambda { |r| video_token_from(r[:path]) },
        :if       => lambda { |r| video_token?(r[:path]) && eu_location?(r[:edge_location]) }
      )
      analyze.traffic(:sc_bytes, :title => :traffic_as,
        :category => lambda { |r| video_token_from(r[:path]) },
        :if       => lambda { |r| video_token?(r[:path]) && as_location?(r[:edge_location]) }
      )
      analyze.traffic(:sc_bytes, :title => :traffic_jp,
        :category => lambda { |r| video_token_from(r[:path]) },
        :if       => lambda { |r| video_token?(r[:path]) && jp_location?(r[:edge_location]) }
      )
      analyze.traffic(:sc_bytes, :title => :traffic_unknown,
        :category => lambda { |r| video_token_from(r[:path]) },
        :if       => lambda { |r| video_token?(r[:path]) && unknown_location?(r[:edge_location]) }
      )
      analyze.frequency(:path, :title => :requests_us,
        :category => lambda { |r| video_token_from(r[:path]) },
        :if       => lambda { |r| video_token?(r[:path]) && us_location?(r[:edge_location]) }
      )
      analyze.frequency(:path, :title => :requests_eu,
        :category => lambda { |r| video_token_from(r[:path]) },
        :if       => lambda { |r| video_token?(r[:path]) && eu_location?(r[:edge_location]) }
      )
      analyze.frequency(:path, :title => :requests_as,
        :category => lambda { |r| video_token_from(r[:path]) },
        :if       => lambda { |r| video_token?(r[:path]) && as_location?(r[:edge_location]) }
      )
      analyze.frequency(:path, :title => :requests_jp,
        :category => lambda { |r| video_token_from(r[:path]) },
        :if       => lambda { |r| video_token?(r[:path]) && jp_location?(r[:edge_location]) }
      )
      analyze.frequency(:path, :title => :requests_unknown,
        :category => lambda { |r| video_token_from(r[:path]) },
        :if       => lambda { |r| video_token?(r[:path]) && unknown_location?(r[:edge_location]) }
      )
      analyze.trackers
    end
    
  end
end