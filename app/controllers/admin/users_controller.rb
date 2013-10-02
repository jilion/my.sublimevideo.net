class Admin::UsersController < Admin::AdminController
  respond_to :html, except: [:stats, :invoices, :support_requests]
  respond_to :js, only: [:index, :stats, :invoices, :support_requests]

  before_filter :_set_default_scopes, only: [:index]
  before_filter :_set_user, only: [:update, :destroy, :become, :stats, :invoices, :support_requests, :new_support_request, :oauth_revoke]
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
    @user_tags = User.tag_counts.order('tags.name')
    @site_tags = Site.tag_counts.order('tags.name')

    respond_with(@users, per_page: 50)
  end

  # GET /users/:id
  def show
    redirect_to edit_admin_user_path(params[:id])
  end

  # GET /users/:id/edit
  def edit
    @user = User.includes(:enthusiast, :feedbacks).find(params[:id])
    @tags = User.tag_counts.order('tags.name')
    @oauth_authorizations = @user.tokens.valid

    respond_with(@user)
  end

  # PUT /users/:id
  def update
    @user.update(_user_params)

    respond_with(@user, notice: 'User has been successfully updated.') do |format|
      format.js   { render 'admin/shared/flash_update' }
      format.html { redirect_to [:edit, :admin, @user] }
    end
  end

  # DELETE /users/:id
  def destroy
    respond_to do |format|
      if UserManager.new(@user).archive(skip_password: true)
        flash[:notice] = 'User has been successfully archived.'
      else
        flash[:error] = 'User has not been successfully archived!'
      end
      format.html { redirect_to [:edit, :admin, @user] }
    end
  end

  # GET /users/:id/become
  def become
    sign_in(@user, bypass: true)

    redirect_to root_url(subdomain: 'my')
  end

  # GET /users/:id/stats
  def stats
  end

  # GET /users/:id/invoices
  def invoices
  end

  # GET /users/:id/support_requests
  def support_requests
  end

  # GET /users/:id/new_support_request
  def new_support_request
    SupportRequestManager.create_zendesk_user(@user)

    redirect_to ENV['ZENDESK_BASE_URL'] + "/tickets/new?requester_id=#{@user.zendesk_id}"
  end

  # DELETE /users/:id/oauth_revoke
  def oauth_revoke
    @token = @user.tokens.where(token: params[:token]).first!
    @token.invalidate!

    redirect_to edit_admin_user_path(@user), notice: "Authorization for the application '#{@token.client_application.name}' has been revoked."
  end

  private

  def _set_user
    @user = User.find(params[:id])
  end

  def _user_params
    params.require(:user).permit!
  end

end
