require_dependency 'service/kit'
require_dependency 'service/addon/custom_logo'

class KitsController < ApplicationController
  respond_to :js, only: [:process_custom_logo]

  before_filter :redirect_suspended_user, :find_site_by_token!
  before_filter :find_kit, only: [:show, :edit, :update, :set_as_default, :process_custom_logo]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index, :new, :create, :show, :edit, :update]
  skip_before_filter :verify_authenticity_token, only: [:process_custom_logo]

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

    respond_with(@kit, location: [@site, :kits])
  end

  # PUT /sites/:site_id/players/:id/set_as_default
  def set_as_default
    @site.touch(:settings_updated_at)
    @site.update_attributes(default_kit_id: @kit.id)
    Service::Settings.delay.update_all_types!(@site.id)

    redirect_to [@site, :kits]
  end

  # POST /sites/:site_id/players/:id/process_custom_logo
  def process_custom_logo
    @custom_logo = Addons::CustomLogo.new(params[:file])
    service = Service::Addon::CustomLogo.new(@kit, @custom_logo, params[:old_custom_logo_path])
    service.upload!
    @logo_path, @logo_width, @logo_height = service.current_path, service.width, service.height
  end

  private

  def find_kit
    @kit = exhibit(@site.kits.find_by_identifier(params[:id]))
  rescue ActiveRecord::RecordNotFound
    redirect_to [@site, :kits] and return
  end
end
