class Admin::AdminsController < Admin::AdminController
  respond_to :js, :html

  has_scope :by_date

  def index
    @admins = Admin.where(:encrypted_password.not_eq => nil)
    @admins = apply_scopes(@admins).by_date
    respond_with(@admins)
  end

  def destroy
    @admin = Admin.find(params[:id])
    @admin.destroy
    respond_with(@admin, location: [:admin, :admins])
  end

end
