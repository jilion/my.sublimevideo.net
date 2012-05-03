class Admin::UsersController < Admin::AdminController
  respond_to :html, :js

  before_filter { |controller| require_role?('marcom') if %w[update].include?(action_name) }

  # filter
  has_scope :free, type: :boolean
  has_scope :paying, type: :boolean
  has_scope :with_state do |controller, scope, value|
    scope.with_state(value.to_sym)
  end
  has_scope :with_balance, type: :boolean
  # sort
  has_scope :by_name_or_email
  # has_scope :by_sites_last_30_days_billable_video_views
  has_scope :by_last_invoiced_amount
  has_scope :by_total_invoiced_amount
  has_scope :by_date
  # search
  has_scope :search

  # GET /users
  def index
    params[:with_state] = 'active' unless params.keys.any? { |k| %w[free with_state search with_balance by_sites_last_30_days_billable_video_views].include?(k) }
    params[:by_date] = 'desc' unless params[:by_date]
    # @users = if params.key?(:by_sites_last_30_days_billable_video_views)
    #   User
    # else
    @users = User.includes(:sites, :invoices).select("users.*")
    # end
    @users = apply_scopes(@users)

    respond_with(@users, per_page: 50)
  end

  # GET /users/:id
  def show
    redirect_to edit_admin_user_path(params[:id])
  end

  # GET /users/:id/edit
  def edit
    @user = User.includes(:enthusiast).find(params[:id])

    respond_with(@user)
  end

  # GET /users/:id/become
  def become
    sign_in(User.find(params[:id]), bypass: true)

    redirect_to root_url(subdomain: 'my')
  end

  # PUT /users/:id
  def update
    @user = User.find(params[:id])
    @user.vip = params[:user][:vip]
    @user.save!

    respond_with(@user, location: admin_user_path(@user))
  end

end
