class Admin::UsersController < Admin::AdminController
  respond_to :js, :html
  
  has_scope :enthusiast, :type => :boolean
  has_scope :beta, :type => :boolean
  has_scope :with_activity, :type => :boolean
  has_scope :use_personal, :type => :boolean
  has_scope :use_company, :type => :boolean
  has_scope :use_clients, :type => :boolean
  # sort
  has_scope :by_name_or_email
  has_scope :by_beta
  has_scope :by_player_hits
  has_scope :by_traffic
  has_scope :by_date, :default => 'desc', :always => true do |controller, scope, value|
    controller.params.keys.any? { |k| k != "by_date" && k =~ /(by_\w+)/ } ? scope : scope.by_date(value)
  end
  # search
  has_scope :search
  
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