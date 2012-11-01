require_dependency 'service/kit'

class KitsController < ApplicationController
  before_filter :redirect_suspended_user, :find_site_by_token!
  before_filter :find_kit, only: [:show, :edit, :update]
  before_filter :find_sites_or_redirect_to_new_site

  # GET /sites/:site_id/players
  def index
    @kits = @site.kits
    respond_with(@kits)
  end

  # GET /sites/:site_id/players/new
  def new
    @kit = exhibit(@site.kits.build({ app_design_id: App::Design.get('classic').id }, as: :admin))
    respond_with(@kit)
  end

  # GET /sites/:site_id/players/:id
  def show
    respond_with(@kit) do |format|
      format.js
      format.html { redirect_to edit_site_kit_path(params[:site_id], params[:id]) }
    end
  end

  # GET /sites/:site_id/players/:id/edit
  def edit
  end


  # PUT /sites/:site_id/players/:id
  def update
    Service::Kit.new(@kit).update(params[:kit])

    redirect_to edit_site_kit_path(@site, @kit)
  end

  private

  def find_kit
    @kit = exhibit(@site.kits.find(params[:id]))
  rescue ActiveRecord::RecordNotFound
    redirect_to edit_site_kit_path(@site, @site.kits.first.id) and return
  end
end
