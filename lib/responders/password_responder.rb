module Responders
  module PasswordResponder
    
    # TODO: Test this responder
    def initialize(controller, resources, options={})
      super
      @password_required = options.delete(:password_required)
    end
    
    delegate :params, :current_user, :to => :controller
    
    def to_html
      require_password!
      super
    end
    
    def to_js
      require_password!
      super
    end
    
  protected
    
    def require_password!
      add_error_to_resource! if password_required? && !valid_password?
    end
    
    def add_error_to_resource!
      resources.last.errors[:base] << "Your password is needed to modify this #{resources.last.class.to_s.downcase}."
    end
    
    def add_alert_flash!
      controller.flash[:alert] = "The given password is invalid!"
    end
    
    def password_required?
      @password_required || false
    end
    
    def valid_password?
      if current_user && params[:password]
        current_user.valid_password?(params[:password])
      else
        false
      end
    end
    
  end
end