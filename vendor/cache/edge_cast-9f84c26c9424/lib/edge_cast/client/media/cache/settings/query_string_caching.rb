module EdgeCast
  class Client
    module Media
      module Cache
        module Settings
          module QueryStringCaching

            require 'edge_cast/client/media/cache/settings'
            include EdgeCast::Client::Media::Cache::Settings

            def query_string_caching(media_type = nil)
              wrap_field_per_media(get("querystringcaching#{settings_query_string(media_type)}"), :query_string_caching)
            end

            def update_query_string_caching(media_type, caching)
              put('querystringcaching', { :media_type_id => Media.from_key(media_type)[:code], :query_string_caching => caching }.to_api!)
            end

          end
        end
      end
    end
  end
end
