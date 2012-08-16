require 'edge_cast/core_ext/hash'

module EdgeCast
  class Client
    module Media
      module Cache
        module Settings
          module QueryStringLogging

            require 'edge_cast/client/media/cache/settings'
            include EdgeCast::Client::Media::Cache::Settings

            def query_string_logging(media_type = nil)
              wrap_field_per_media(get("querystringlogging#{settings_query_string(media_type)}"), :query_string_logging)
            end

            def update_query_string_logging(media_type, logging)
              put('querystringlogging', { :media_type_id => Media.from_key(media_type)[:code], :query_string_logging => logging }.to_api!)
            end

          end
        end
      end
    end
  end
end
