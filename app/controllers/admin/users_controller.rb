class Admin::UsersController < Admin::AdminController
  respond_to :html, :js

  # filter
  has_scope :tagged_with
  has_scope :free, :paying, :with_balance, type: :boolean
  has_scope(:with_state) { |controller, scope, value| scope.with_state(value.to_sym) }
  # sort
  has_scope :by_name_or_email, :by_sites_last_30_days_billable_video_views,
            :by_last_invoiced_amount, :by_total_invoiced_amount, :by_date
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
    @tags  = User.tag_counts

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
    @user.save!

    respond_with(@user, location: [:edit, :admin, @user], notice: 'User was successfully updated.')
  end

  # GET /users/:id/become
  def become
    sign_in(User.find(params[:id]), bypass: true)

    redirect_to root_url(subdomain: 'my')
  end

  def autocomplete_tag_list
    @word = params[:word]
    match = "%#{@word}%"
    @tags = User.tag_counts_on(:tags).where { lower(:name) =~ lower(match) }.order(:name).limit(10)

    render '/admin/shared/autocomplete_tag_list'
  end

end
