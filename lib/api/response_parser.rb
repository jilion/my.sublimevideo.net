module Api
  class ResponseParser < Faraday::Response::Middleware
    def on_complete(env)
      env[:body] = parse_body(env[:body])
      env[:body] = parse_headers(env)
    end

    private

    def parse_body(body)
      json = MultiJson.load(body, symbolize_keys: true)
      {
        :data => json,
        :errors => json.delete(:errors) || {},
        :metadata => json.delete(:metadata) || {}
      }
    end

    def parse_headers(env)
      env[:response_headers].tap do |headers|
        env[:body][:metadata][:page] = headers['X-Page'].to_i if headers.include?('X-Page')
        env[:body][:metadata][:per_page] = headers['X-Per-Page'].to_i if headers.include?('X-Per-Page')
        env[:body][:metadata][:total_count] = headers['X-Total-Count'].to_i if headers.include?('X-Total-Count')
      end
      env[:body]
    end
  end
end
