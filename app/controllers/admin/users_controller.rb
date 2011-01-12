class Admin::UsersController < Admin::AdminController
  respond_to :js, :html

  # filter
  has_scope :active_and_billable, :type => :boolean
  has_scope :active_and_not_billable, :type => :boolean
  has_scope :will_be_suspended, :type => :boolean
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
    @users = User.includes(:sites, :invoices)
    if params.keys.all? { |k| k =~ /^by_/ || %w[action controller search].include?(k) }
      @users = @users.active_and_billable
    end
    @users = apply_scopes(@users).by_date
    respond_with(@users)
  end

  # GET /admin/users/:id
  def show
    @user = User.find(params[:id])
    respond_with(@user)
  end

end
