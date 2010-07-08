class Admin::EnthusiastsController < Admin::AdminController
  
  def index
    @enthusiasts = Enthusiast.where(:confirmed_at.ne => nil).includes(:user, :sites)
    respond_with(@enthusiasts)
  end
  
end