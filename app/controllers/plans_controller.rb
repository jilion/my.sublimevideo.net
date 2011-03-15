class PlansController < ApplicationController

  before_filter :redirect_suspended_user
  before_filter :find_site_by_token

  # GET /sites/:site_id/plan/edit
  def edit
    respond_with(@site)
  end

  # PUT /sites/:site_id/plan
  def update
    @site.update_attributes(params[:site])
    respond_with(@site, :location => :sites)
  end

private

  def find_site_by_token
    @site = current_user.sites.find_by_token(params[:site_id])
  end

end
