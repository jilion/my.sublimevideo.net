require_dependency 'service/kit'

class KitsController < ApplicationController
  before_filter :redirect_suspended_user
  before_filter :find_sites_or_redirect_to_new_site, only: [:edit]
  before_filter :find_site_by_token!, :find_kit

  # GET /sites/:site_id/kits/:id
  def show
    respond_with(@kit) do |format|
      format.js
      format.html { redirect_to edit_site_kit_path(params[:site_id], params[:id]) }
    end
  end

  # GET /sites/:site_id/kits/:id/edit
  def edit
  end


  # PUT /sites/:site_id/kits/:id
  def update
    Service::Kit.new(@kit).update_settings!(params[:kit])

    redirect_to edit_site_kit_path(@site, @kit)
  end

  private

  def find_kit
    @kit = exhibit(@site.kits.find(params[:id]))
  rescue ActiveRecord::RecordNotFound
    redirect_to edit_site_kit_path(@site, @site.kits.first.id) and return
  end
end
