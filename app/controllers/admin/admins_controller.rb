class Admin::AdminsController < Admin::AdminController
  respond_to :js, :html
  
  has_scope :by_date
  
  def index
    @admins = apply_scopes(Admin.where(:encrypted_password.ne => nil).by_date)
    respond_with(@admins)
  end
  
  def destroy
    @admin = Admin.find(params[:id])
    @admin.destroy
    respond_with(@admin) do |format|
      format.html { redirect_to admin_admins_path }
    end
  end
  
end