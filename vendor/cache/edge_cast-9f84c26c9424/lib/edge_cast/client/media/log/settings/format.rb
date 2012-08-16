require 'edge_cast/core_ext/hash'

module EdgeCast
  class Client
    module Media
      module Log
        module Settings
          module Format

            def log_format
              get('logformat').to_result!
            end

            def update_log_format(params = {})
              put('logformat', params.to_api!)
            end

          end
        end
      end
    end
  end
end
