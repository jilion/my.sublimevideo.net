require 'edge_cast/core_ext/hash'

module EdgeCast
  class Client
    module Media
      module Cache
        module Management

          def load(media_type, path)
            put('edge/load', management_params(media_type, path))
          end

          def purge(media_type, path)
            put('edge/purge', management_params(media_type, path))
          end

          private

          def management_params(media_type, path)
            { :media_type => Media.from_key(media_type.to_sym)[:code], :media_path => path }.to_api!
          end

        end
      end
    end
  end
end
