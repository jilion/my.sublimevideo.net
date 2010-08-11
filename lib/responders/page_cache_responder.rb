module Responders
  module PageCacheResponder
    
    def to_html
      controller.response.headers['Cache-Control'] = "public, max-age=#{1.month}"
      super
    end
    
  end
end