module Responders
  module PageCacheResponder
    
    def to_html
      if Rails.env.production?
        controller.expires_in 1.year, public: true
      end
      super
    end
    
  end
end