require 'edge_cast/core_ext/string'

module EdgeCast
  class Client
    module Media
      module Cache
        module Settings

          private

          def settings_query_string(media_type)
            media_type ? "?mediatypeid=#{EdgeCast::Client::Media.from_key(media_type)[:code]}" : nil
          end

          def wrap_field_per_media(response, field)
            (response.is_a?(Array) ? response : [response]).inject({}) do |hash, r|
              Media.from_code(r['MediaTypeId'])[:keys].each { |key| hash[key] = r[field.camelize] }
              hash
            end
          end

        end
      end
    end
  end
end
