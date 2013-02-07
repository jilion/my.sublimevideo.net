module ControllerHelpers
  module EarlyAccess

    LIST = %w[video embed_addon]

    def early_access?(feature)
      current_user_early_access.include?(feature)
    end

    def early_access_body_class
      current_user_early_access.map do |feature|
        feature.empty? ? nil : "early_access_#{feature}"
      end.compact.join(' ')
    end

    def self.included(base)
      if base.respond_to?(:helper_method)
        base.send :helper_method, :early_access_body_class
        base.send :helper_method, :early_access?
      end
    end

    def current_user_early_access
      if Rails.env.development? && params[:early_access]
        [params[:early_access]]
      else
        current_user.try(:early_access) || []
      end
    end

    def require_video_early_access
      redirect_to root_url unless early_access?('video')
    end

  end
end
