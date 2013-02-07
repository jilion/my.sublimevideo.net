require_dependency 'service/kit'
require_dependency 'service/addon/custom_logo'

class KitsController < ApplicationController
  respond_to :js, only: [:fields, :process_custom_logo]

  before_filter :redirect_suspended_user, :find_site_by_token!
  before_filter :find_design, only: [:new, :create, :edit, :update, :process_custom_logo, :fields]
  before_filter :find_kit, only: [:show, :edit, :update, :set_as_default]
  before_filter :find_or_build_kit, only: [:process_custom_logo, :fields]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index, :new, :create, :show, :edit, :update]
  skip_before_filter :verify_authenticity_token, only: [:process_custom_logo]

  # GET /sites/:site_id/players
  def index
    @kits = @site.kits.includes(:site).order(:id)
    respond_with(@kits)
  end

  # GET /sites/:site_id/players/new
  def new
    @kit = exhibit(@site.kits.build)
    respond_with(@kit)
  end

  # POST /sites/:site_id/players
  def create
    @kit = exhibit(@site.kits.build)
    Service::Kit.new(@kit).save(params[:kit])

    respond_with(@kit, location: [@site, :kits])
  end

  # GET /sites/:site_id/players/:id
  def show
    respond_with(@kit) do |format|
      format.html { redirect_to edit_site_kit_path(params[:site_id], @kit.identifier) }
    end
  end

  # GET /sites/:site_id/players/:id/edit
  def edit
  end

  # PUT /sites/:site_id/players/:id
  def update
    Service::Kit.new(@kit).save(params[:kit])

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

  # GET /sites/:site_id/players/:id/fields
  def fields
    params[:kit][:settings] = Service::SettingsSanitizer.new(@kit, params[:kit][:settings]).sanitize
  end

  private

  def find_or_build_kit
    @kit = exhibit(@site.kits.find_by_identifier!(params[:id]))
  rescue ActiveRecord::RecordNotFound
    @kit = exhibit(@site.kits.build(app_design_id: @design.id))
  end

  def find_kit
    @kit    = exhibit(@site.kits.find_by_identifier!(params[:id]))
    @design = @kit.design
  rescue ActiveRecord::RecordNotFound
    redirect_to [@site, :kits]
  end

  def find_design
    @design = params[:design_id] ? App::Design.find(params[:design_id]) : App::Design.get('classic')
  end

end
