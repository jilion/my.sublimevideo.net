# encoding: utf-8

module LogsFileFormat
  class S3Licenses < RequestLogAnalyzer::FileFormat::Base
    extend RequestLogAnalyzer::FileFormat::CommonRegularExpressions
    extend LogsFileFormat::Amazon

    line_definition :access do |line|
      line.header = true
      line.footer = true
      line.regexp = /^([^\ ]+) ([^\ ]+) \[(#{timestamp('%d/%b/%Y:%H:%M:%S %z')})?\] (#{ip_address}) ([^\ ]+) ([^\ ]+) ([^\ ]+) ([^\ ]+) "([^"]+)" (\d+) ([^\ ]+) ([^\ ]+) ([^\ ]+) ([^\ ]+) ([^\ ]+) "([^"]*)" "([^"]*)"/

      line.capture(:bucket_owner)
      line.capture(:bucket)
      line.capture(:timestamp).as(:timestamp)
      line.capture(:remote_ip)
      line.capture(:requester)
      line.capture(:requests_id)
      line.capture(:operation)
      line.capture(:key).as(:nillable_string)
      line.capture(:requests_uri)
      line.capture(:http_status).as(:integer)
      line.capture(:error_code).as(:nillable_string)
      line.capture(:bytes_sent).as(:traffic, :unit => :byte)
      line.capture(:object_size).as(:traffic, :unit => :byte)
      line.capture(:total_time).as(:duration, :unit => :msec)
      line.capture(:turnaround_time).as(:duration, :unit => :msec)
      line.capture(:referrer).as(:referrer)
      line.capture(:useragent).as(:useragent)
    end

    report do |analyze|
      analyze.traffic(:bytes_sent, :title => :traffic_s3,
        :category => lambda { |r| license_token_from(r[:key]) },
        :if       => lambda { |r| license_token?(r[:key]) && s3_get_request?(r[:operation]) }
      )
      analyze.frequency(:key, :title => :requests_s3,
        :category => lambda { |r| license_token_from(r[:key]) },
        :if       => lambda { |r| license_token?(r[:key]) && s3_get_request?(r[:operation]) }
      )
    end

    class Request < RequestLogAnalyzer::Request

      # Do not use DateTime.parse, but parse the timestamp ourselves to return a integer
      # to speed up parsing.
      def convert_timestamp(value, definition)
        "#{value[7,4]}#{MONTHS[value[3,3]]}#{value[0,2]}#{value[12,2]}#{value[15,2]}#{value[18,2]}".to_i
      end

      # Make sure that the string '-' is parsed as a nil value.
      def convert_nillable_string(value, definition)
        value == '-' ? nil : value
      end

      # Can be implemented in subclasses for improved categorizations
      def convert_referrer(value, definition)
        value == '-' ? nil : value
      end

      # Can be implemented in subclasses for improved categorizations
      def convert_useragent(value, definition)
        value == '-' ? nil : value
      end
    end

  end
end