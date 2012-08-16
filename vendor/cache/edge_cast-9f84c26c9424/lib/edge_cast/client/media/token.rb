require 'edge_cast/core_ext/hash'

module EdgeCast
  class Client
    module Media
      module Token

        def encrypt_token_data(params = {})
          put('token/encrypt', params.to_api!).to_result!
        end

      end
    end
  end
end
