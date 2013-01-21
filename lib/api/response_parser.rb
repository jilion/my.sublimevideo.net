module Api
  class ResponseParser < Faraday::Response::Middleware
    def on_complete(env)
      env[:body] = parse_body(env[:body])
      env[:body] = parse_headers(env)
    end

    private

    def parse_body(body)
      default_body = {
        :data => {},
        :errors => {},
        :metadata => {}
      }
      if body.present?
        json = MultiJson.load(body, symbolize_keys: true)
        default_body[:errors]   = json.delete(:errors) if json.include?(:errors)
        default_body[:metadata] = json.delete(:metadata) if json.include?(:metadata)
        default_body[:data]     = json
      end
      default_body
    end

    def parse_headers(env)
      env[:response_headers].tap do |headers|
        env[:body][:metadata][:page] = headers['X-Page'].to_i if headers.include?('X-Page')
        env[:body][:metadata][:limit] = headers['X-Limit'].to_i if headers.include?('X-Limit')
        env[:body][:metadata][:offset] = headers['X-Offset'].to_i if headers.include?('X-Offset')
        env[:body][:metadata][:total_count] = headers['X-Total-Count'].to_i if headers.include?('X-Total-Count')
      end
      env[:body]
    end
  end
end
