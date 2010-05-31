module LogsFileFormat

  class Voxcast < RequestLogAnalyzer::FileFormat::Base
    
    extend RequestLogAnalyzer::FileFormat::CommonRegularExpressions
    
    LINE_DEFINITIONS = [
      { :regexp => '(\d+|\-)',                   :captures => [{:name => :cache_miss_reason, :type => :integer}] },
      { :regexp => '(\d+|\-)',                   :captures => [{:name => :cache_status,      :type => :integer}] },
      { :regexp => "(#{ip_address})",            :captures => [{:name => :client_ip,         :type => :string}] },
      { :regexp => "(#{timestamp('%Y-%m-%d')})", :captures => [{:name => :log_date,          :type => :timestamp}] },
      { :regexp => "(#{timestamp('%Y-%m-%d')})", :captures => [{:name => :date,              :type => :timestamp}] },
      { :regexp => '(\d{3})',                    :captures => [{:name => :first_http_status, :type => :integer}] },
      { :regexp => '(\S+)',                      :captures => [{:name => :http_method,       :type => :string}] },
      { :regexp => '\"(.*)\"',                   :captures => [{:name => :http_request,      :type => :string}] },
      { :regexp => '(\d{3})',                    :captures => [{:name => :http_status,       :type => :integer}] },
      { :regexp => '\"(.*)\"',                   :captures => [{:name => :referer,           :type => :string}] },
      { :regexp => '\"(.*)\"',                   :captures => [{:name => :path,              :type => :string}] },
      { :regexp => '\"(.*)\"',                   :captures => [{:name => :path_query,        :type => :string}] },
      { :regexp => '\"(.*)\"',                   :captures => [{:name => :path_stem,         :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :rfc_1413_identity, :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :server_name,       :type => :string}] },
      { :regexp => '(\d+|-)',                    :captures => [{:name => :request_bytes,     :type => :traffic}] },
      { :regexp => '(\d+|-)',                    :captures => [{:name => :response_bytes,    :type => :traffic}] },
      { :regexp => "(#{timestamp('%H:%M:%S')})", :captures => [{:name => :log_time,          :type => :timestamp}] },
      { :regexp => "(#{timestamp('%H:%M:%S')})", :captures => [{:name => :time,              :type => :timestamp}] },
      { :regexp => '(\d+|-)',                    :captures => [{:name => :duration,          :type => :duration, :unit => :musec}] },
      { :regexp => '\"(.*)\"',                   :captures => [{:name => :user_agent,        :type => :string}] },
      { :regexp => '(.*)',                       :captures => [{:name => :user_id,           :type => :string}] }
    ]
    
    def self.create(*args)
      # line_definitions = line_definer.line_definitions.merge(:default => line_definition)
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
        :regexp => Regexp.new(regexps.join('\s')),
        :captures => captures,
        :header => true,
        :footer => true
      )
    end
    
    def self.report_trackers
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      analyze.frequency :path, :title => :loader, :if => lambda { |r| r[:path] =~ /\/js\/[a-z0-9]{8}\.js.*/ }
      analyze.frequency :path, :title => :js,     :if => lambda { |r| r[:path] =~ /\/p\/sublime\.js\?t=[a-z0-9]{8}.*/ }
      analyze.frequency :path, :title => :flash,  :if => lambda { |r| r[:path] =~ /\/p\/sublime\.swf\?t=[a-z0-9]{8}.*/ }
      # analyze.frequency :referer
      # analyze.frequency :referer,  :title => 'js referer', :if => lambda { |r| r[:path] == "/js/test.txt" }
      # analyze.traffic :response_bytes,  :category => lambda { |r| r[:path] }
      analyze.trackers
    end
    
  end
  
end