class KitsController < ApplicationController
  respond_to :js, only: [:fields, :process_custom_logo]

  before_filter :redirect_suspended_user, :_set_site
  before_filter :_set_design, only: [:new, :create, :edit, :update, :process_custom_logo, :fields]
  before_filter :_set_kit_and_design, only: [:show, :edit, :update, :set_as_default]
  before_filter :_set_kit, only: [:process_custom_logo, :fields]
  before_filter :_set_sites_or_redirect_to_new_site, only: [:index, :new, :create, :show, :edit, :update]
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
    KitManager.new(@kit).save(_kit_params)

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
    KitManager.new(@kit).save(_kit_params)

    respond_with(@kit, location: [@site, :kits])
  end

  # PUT /sites/:site_id/players/:id/set_as_default
  def set_as_default
    @site.touch(:settings_updated_at)
    @site.update(default_kit_id: @kit.id)
    SettingsGenerator.delay.update_all!(@site.id)

    redirect_to [@site, :kits]
  end

  # POST /sites/:site_id/players/:id/process_custom_logo
  def process_custom_logo
    @custom_logo = Addons::CustomLogo.new(params[:file])
    uploader = Addons::CustomLogoUploader.new(@kit, @custom_logo, params[:old_custom_logo_path])
    uploader.upload!
    @logo_path, @logo_width, @logo_height = uploader.path, uploader.width, uploader.height
  end

  # GET /sites/:site_id/players/:id/fields
  def fields
    params[:kit][:settings] = SettingsSanitizer.new(@kit, params[:kit][:settings]).sanitize
  end

  private

  def _set_kit
    @kit = exhibit(@site.kits.where(identifier: params[:id])).first!
  rescue ActiveRecord::RecordNotFound
    @kit = exhibit(@site.kits.build(design_id: @design.id))
  end

  def _set_kit_and_design
    @kit    = exhibit(@site.kits.where(identifier: params[:id])).first!
    @design = @kit.design
  rescue ActiveRecord::RecordNotFound
    redirect_to [@site, :kits]
  end

  def _set_design
    @design = params[:design_id] ? Design.find(params[:design_id]) : Design.get('classic')
  end

  def _kit_params
    params.require(:kit).permit(:name, :design_id).merge(settings: params[:kit][:settings])
  end

end
