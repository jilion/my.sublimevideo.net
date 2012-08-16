require 'edge_cast/core_ext/hash'

module EdgeCast
  class Client
    module Media
      module Log
        module Settings
          module Storage

            def log_storage
              get('logstorage').to_result!
            end

            def update_log_storage(params = {})
              put('logstorage', params.to_api!)
            end

          end
        end
      end
    end
  end
end
