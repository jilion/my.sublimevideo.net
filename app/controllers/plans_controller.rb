class PlansController < ApplicationController

  before_filter :redirect_suspended_user
  before_filter :find_site_by_token
  before_filter :redirect_wrong_password_to!, :only => :update

  # GET /sites/:site_id/plan/edit
  def edit
    respond_with(@site) do |format|
      format.html
    end
  end

  # PUT /sites/:site_id/plan
  def update
    @site.update_attributes(params[:site])
    respond_with(@site, :location => :sites) do |format|
      format.html
    end
  end

private

  def find_site_by_token
    @site = current_user.sites.find_by_token(params[:site_id])
  end

  def redirect_wrong_password_to!
    redirect_wrong_password_to(edit_site_plan_path(@site))
  end

end
