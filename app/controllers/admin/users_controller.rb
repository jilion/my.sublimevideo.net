class Admin::UsersController < Admin::AdminController
  respond_to :js, :html

  before_filter :compute_date_range, :only => :show

  # filter
  has_scope :active_and_billable, :type => :boolean
  has_scope :active_and_not_billable, :type => :boolean
  has_scope :with_state do |controller, scope, value|
    scope.with_state(value.to_sym)
  end
  # sort
  has_scope :by_name_or_email
  has_scope :by_sites_last_30_days_billable_player_hits_total_count
  has_scope :by_last_invoiced_amount
  has_scope :by_total_invoiced_amount
  has_scope :by_date
  # search
  has_scope :search

  # GET /admin/users
  def index
    params[:active_and_billable] = true if !params.key?(:active_and_not_billable) && !params.key?(:with_state)
    @users = User.includes(:sites, :invoices)
    @users = @users.select("DISTINCT users.*") unless params.key? :by_sites_last_30_days_billable_player_hits_total_count
    @users = apply_scopes(@users).by_date
    respond_with(@users, :per_page => 50)
  end

  # GET /admin/users/:id
  def show
    @user = User.find(params[:id])
    respond_with(@user)
  end
  
  # GET /admin/users/:id/become
  def become
    sign_in(:user, User.find(params[:id]))
    redirect_to root_path
  end

end
