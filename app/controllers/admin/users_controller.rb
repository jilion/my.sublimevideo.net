class Admin::UsersController < Admin::AdminController
  respond_to :html, :js

  before_filter :set_default_scopes, only: [:index]
  before_filter { |controller| require_role?('marcom') if %w[update].include?(action_name) }

  # filter
  has_scope :tagged_with, :sites_tagged_with, :with_state
  has_scope :free, :paying, :with_balance, type: :boolean

  # sort
  has_scope :by_name_or_email, :by_last_invoiced_amount, :by_total_invoiced_amount, :by_date

  # search
  has_scope :search

  # GET /users
  def index
    @users = apply_scopes(User.includes(:sites, :invoices))
    @user_tags = User.tag_counts
    @site_tags = Site.tag_counts

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

  # PUT /users/:id
  def update
    @user = User.find(params[:id])
    @user.tag_list = params[:user][:tag_list] if params[:user][:tag_list]
    @user.vip      = params[:user][:vip] if params[:user][:vip]
    @user.save!

    respond_with(@user, location: [:edit, :admin, @user], notice: 'User was successfully updated.')
  end

  # GET /users/:id/become
  def become
    sign_in(User.find(params[:id]), bypass: true)

    redirect_to root_url(subdomain: 'my')
  end

  # POST /users/:id/new_ticket
  def new_ticket
    @user = User.find(params[:id])
    @user.create_zendesk_user

    redirect_to ZendeskConfig.base_url + "/tickets/new?requester_id=#{@user.zendesk_id}"
  end

  def autocomplete_tag_list
    @word = params[:word]
    match = "%#{@word}%"
    @tags = User.tag_counts_on(:tags).where { lower(:name) =~ lower(match) }.order(:name).limit(10)

    render '/admin/shared/autocomplete_tag_list'
  end

  private

  def set_default_scopes
    params[:with_state] = 'active' if (scopes_configuration.keys & params.keys.map(&:to_sym)).empty?
    params[:by_date]    = 'desc' unless params.keys.any? { |k| k =~ /^by_\w+$/ }
  end

end
