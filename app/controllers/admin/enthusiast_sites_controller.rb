class Admin::EnthusiastSitesController < Admin::AdminController
  respond_to :js

  # POST /enthusiast_sites/1
  def update
    @enthusiast_site = EnthusiastSite.find(params[:id])
    @enthusiast_site.update_attributes(params[:enthusiast_site])
    respond_with(@enthusiast_site)
  end

end
