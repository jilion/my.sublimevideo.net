class Admin::UsersController < Admin::AdminController
  respond_to :js, :html
  
  # GET /admin/users
  def index
    @users = User.scoped.includes(:sites)
    respond_with(@users)
  end
  
  # GET /admin/users/1
  def show
    @user = User.find(params[:id])
    respond_with(@user)
  end
  
end