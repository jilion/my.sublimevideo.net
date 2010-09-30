class Sites::AddonsController < ApplicationController
  respond_to :js
  
  # GET /sites/1/addons/edit
  def edit
    @site = current_user.sites.find(params[:site_id])
    respond_with(@site) do |format|
      format.html { redirect_to sites_path }
      format.js
    end
  end
  
  # PUT /sites/1/addons
  def update
    @site = current_user.sites.find(params[:site_id])
    respond_with(@site) do |format|
      if @site.update_attributes(params[:site])
        @site.delay.activate # re-generate license file
        format.html { redirect_to sites_path }
        format.js
      else
        format.html { redirect_to sites_path }
        format.js   { render :edit }
      end
    end
  end
  
end