module LogsFileFormat
  class CloudfrontDownload < RequestLogAnalyzer::FileFormat::Base
    extend RequestLogAnalyzer::FileFormat::CommonRegularExpressions
    
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
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      analyze.frequency(:path, :title => :hits,
        :category => lambda { |r| r[:path].match(/^\/([a-z0-9]{8})\/.*/) && $1 },
        :if       => lambda { |r| r[:http_status] == 200 && r[:path] =~ /^\/[a-z0-9]{8}\/.*/ }
      )
      analyze.traffic(:sc_bytes, :title => :bandwidth,
        :category => lambda { |r| r[:path].match(/^\/([a-z0-9]{8})\/.*/) && $1 },
        :if       => lambda { |r| r[:path] =~ /^\/[a-z0-9]{8}\/.*/ }
      )
      analyze.trackers
    end
    
  end
end