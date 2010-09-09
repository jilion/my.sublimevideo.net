class Admin::UsersController < Admin::AdminController
  respond_to :js, :html
  
  has_scope :enthusiast, :type => :boolean
  has_scope :beta, :type => :boolean
  has_scope :with_activity, :type => :boolean
  
  # GET /admin/users
  def index
    @users = apply_scopes(User.includes(:sites))
    respond_with(@users)
  end
  
  # GET /admin/users/1
  def show
    @user = User.find(params[:id])
    respond_with(@user)
  end
  
end