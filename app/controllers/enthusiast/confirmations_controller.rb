class Enthusiast::ConfirmationsController < Devise::ConfirmationsController
  
  layout 'enthusiast'
  
  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    
    if resource.errors.empty?
      set_flash_message :notice, :confirmed
      redirect_to root_url
    else
      render_with_scope :new
    end
  end
  
end