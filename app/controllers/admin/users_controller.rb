class Admin::UsersController < Admin::AdminController
  
  # GET /admin/users
  def index
    @users = User.includes(:sites, :videos)
    respond_with(@users)
  end
  
  # GET /admin/users/1
  def show
    @user = User.find(params[:id])
    respond_with(@user)
  end
  
end