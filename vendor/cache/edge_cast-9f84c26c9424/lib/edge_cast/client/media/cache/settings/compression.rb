require 'edge_cast/core_ext/hash'

module EdgeCast
  class Client
    module Media
      module Cache
        module Settings
          module Compression

            def compression(media_type = nil)
              response = get("compression#{settings_query_string(media_type)}")

              (response.is_a?(Array) ? response : [response]).inject({}) do |hash, r|
                return hash unless Media.valid_type?(r['MediaTypeId'])

                Media.from_code(r['MediaTypeId'])[:keys].each { |key| hash[key] = r.to_result! }
                hash
              end
            end

            def enable_compression(media_type, content_types)
              update_compression(media_type, content_types, 1)
            end

            def disable_compression(media_type, content_types)
              update_compression(media_type, content_types, 0)
            end

            private

            def update_compression(media_type, content_types, status)
              put('compression', { :media_type_id => Media.from_key(media_type)[:code], :status => status, :content_types => content_types }.to_api!)
            end

          end
        end
      end
    end
  end
end
