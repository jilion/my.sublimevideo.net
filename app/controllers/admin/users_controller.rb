class Admin::UsersController < Admin::AdminController
  
  def index
    @users = User.includes(:sites, :videos)
    respond_with(@users)
  end
  
end