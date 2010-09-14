class Admin::UsersController < Admin::AdminController
  respond_to :js, :html
  
  has_scope :enthusiast, :type => :boolean
  has_scope :beta, :type => :boolean
  has_scope :with_activity, :type => :boolean
  # sort
  has_scope :by_name_or_email
  has_scope :by_beta
  has_scope :by_use_personal
  has_scope :by_user_company
  has_scope :by_user_clients
  has_scope :by_player_hits
  has_scope :by_traffic
  has_scope :by_date
  
  # GET /admin/users
  def index
    @users = apply_scopes(User.includes(:sites), :default => { :by_date => 'asc' })
    respond_with(@users)
  end
  
  # GET /admin/users/1
  def show
    @user = User.find(params[:id])
    respond_with(@user)
  end
  
end