require_dependency 'zendesk/zendesk_config'

class Admin::UsersController < Admin::AdminController
  respond_to :html, :js

  before_filter :set_default_scopes, only: [:index]
  before_filter { |controller| require_role?('marcom') if %w[update].include?(action_name) }

  # filter
  has_scope :tagged_with, :sites_tagged_with, :with_state
  has_scope :free, :paying, :with_balance, :vip, type: :boolean

  # sort
  has_scope :by_name_or_email, :by_last_invoiced_amount, :by_total_invoiced_amount, :by_date

  # search
  has_scope :search

  # GET /users
  def index
    @users = apply_scopes(User.includes(:sites, :invoices))
    @user_tags = User.tag_counts.order { tags.name }
    @site_tags = Site.tag_counts.order { tags.name }

    respond_with(@users, per_page: 50)
  end

  # GET /users/:id
  def show
    redirect_to edit_admin_user_path(params[:id])
  end

  # GET /users/:id/edit
  def edit
    @user = User.includes(:enthusiast).find(params[:id])
    @tags = User.tag_counts.order { tags.name }

    respond_with(@user)
  end

  # PUT /users/:id
  def update
    @user = User.find(params[:id])
    @user.update_attributes(params[:user], without_protection: true)

    respond_with(@user, notice: 'User was successfully updated.') do |format|
      format.js   { render 'admin/shared/flash_update' }
      format.html { redirect_to [:edit, :admin, @user] }
    end
  end

  # GET /users/:id/become
  def become
    sign_in(User.find(params[:id]), bypass: true)

    redirect_to root_url(subdomain: 'my')
  end

  # GET /users/:id/new_support_request
  def new_support_request
    @user = User.find(params[:id])
    @user.create_zendesk_user

    redirect_to ZendeskConfig.base_url + "/tickets/new?requester_id=#{@user.zendesk_id}"
  end

  private

  def set_default_scopes
    params[:with_state] = 'active' if (scopes_configuration.keys & params.keys.map(&:to_sym)).empty?
    params[:by_date]    = 'desc' unless params.keys.any? { |k| k =~ /^by_\w+$/ }
  end

end
