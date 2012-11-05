require_dependency 'service/kit'

class KitsController < ApplicationController
  before_filter :redirect_suspended_user, :find_site_by_token!
  before_filter :find_kit, only: [:show, :edit, :update, :set_as_default]
  before_filter :find_sites_or_redirect_to_new_site

  # GET /sites/:site_id/players
  def index
    @kits = @site.kits.order(:id)
    respond_with(@kits)
  end

  # GET /sites/:site_id/players/new
  def new
    @kit = exhibit(@site.kits.build({ app_design_id: App::Design.get('classic').id }, as: :admin))
    respond_with(@kit)
  end

  # POST /sites/:site_id/players
  def create
    @kit = exhibit(@site.kits.build({ name: params[:kit][:name], app_design_id: params[:kit][:app_design_id] }, as: :admin))
    Service::Kit.new(@kit).create(params[:kit])

    respond_with(@kit, location: [@site, :kits])
  end

  # GET /sites/:site_id/players/:id
  def show
    respond_with(@kit) do |format|
      format.js
      format.html { redirect_to [:edit, params[:site_id], params[:id]] }
    end
  end

  # GET /sites/:site_id/players/:id/edit
  def edit
  end

  # PUT /sites/:site_id/players/:id
  def update
    Service::Kit.new(@kit).update(params[:kit])

    respond_with(@kit, location: [:edit, @site, @kit])
  end

  # PUT /sites/:site_id/players/:id/set_as_default
  def set_as_default
    @site.touch(:settings_updated_at)
    @site.update_attributes(default_kit_id: @kit.id)
    Service::Settings.delay.update_all_types!(@site.id)

    redirect_to [@site, :kits]
  end

  private

  def find_kit
    @kit = exhibit(@site.kits.find_by_identifier(params[:id]))
  rescue ActiveRecord::RecordNotFound
    redirect_to [@site, :kits] and return
  end
end
