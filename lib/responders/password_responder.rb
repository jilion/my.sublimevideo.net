module Responders
  module PasswordResponder
    
    # TODO: Test this responder
    def initialize(controller, resources, options = {})
      super
      @password_required = options.delete(:password_required)
    end
    
    delegate :params, :current_user, :to => :controller
    
    def to_html
      if (post? || put?) && password_required? && !valid_password?
        controller.flash[:notice] = nil
        controller.flash[:alert] = "The given password is invalid!"
        redirect_to "/#{resource.class.to_s.downcase.pluralize}/#{resource.to_param}/#{post? ? 'new' : 'edit'}"
      else
        super
      end
    end
    
  protected
    
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