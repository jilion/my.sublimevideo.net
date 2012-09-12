class Admin::AdminsController < Admin::AdminController
  respond_to :js, :html

  before_filter { |controller| require_role?('god') }
  before_filter :find_by_id, only: [:edit, :update, :reset_auth_token, :destroy]

  has_scope :by_date

  # GET /admins
  def index
    @admins = Admin.where{ encrypted_password != nil }
    @admins = apply_scopes(@admins).by_date
    respond_with(@admins)
  end

  # GET /admins/:id/edit
  def edit
  end

  # PUT /admins/:id
  def update
    @admin.update_attributes(params[:admin])
    respond_with(@admin, location: [:admin, :admins])
  end

  # PUT /admins/:id/reset_auth_token
  def reset_auth_token
    @admin.reset_authentication_token!
    respond_with(@admin, location: [:edit, :admin, @admin])
  end

  def destroy
    @admin.destroy
    respond_with(@admin, location: [:admin, :admins])
  end

private

  def find_by_id
    @admin = Admin.find(params[:id])
  end

end
