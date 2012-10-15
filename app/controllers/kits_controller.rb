require_dependency 'service/kit'

class KitsController < ApplicationController
  before_filter :redirect_suspended_user
  before_filter :find_sites_or_redirect_to_new_site, only: [:edit]
  before_filter :find_site_by_token!

  # GET /sites/:site_id/kits/:id
  def show
    redirect_to edit_site_kit_path(params[:site_id], params[:id])
  end

  # GET /sites/:site_id/kits/:id/edit
  def edit
    @kit = exhibit(@site.kits.find(params[:id]))
  rescue ActiveRecord::RecordNotFound
    redirect_to edit_site_kit_path(@site, @site.kits.first.id)
  else
    respond_with(@kit)
  end


  # PUT /sites/:site_id/kits/:id
  def update
    @kit = @site.kits.find(params[:id])
    Service::Kit.new(@kit).update_settings!(params[:kit])

    redirect_to edit_site_kit_path(@site, @kit)
  end

end
