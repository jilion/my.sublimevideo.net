class KitSettingPresenter
  attr_accessor :addon_name, :addon_plan, :settings

  def self.init(*args)
    presenter = self.new(*args)

    if presenter.viable?
      presenter
    else
      presenter = nil
    end
  end

  def initialize(options)
    @kit        = options.fetch(:kit)
    @design     = options.fetch(:design)
    @view       = options.fetch(:view)
    @addon_name = options.fetch(:addon_name)
    @settings   = load_settings
    @addon_plan = load_addon_plan
  end

  def viable?
    @addon_plan && any_settings?
  end

  def any_settings?
    !_addon_plan_settings_record.nil?
  end

  def addon_plan_settings_has_key?(key)
    addon_plan_settings.key?(key.to_sym)
  end

  def render_master_input_field(params = {}, &block)
    @view.haml_concat(render_input_field(params))
    @view.haml_tag(:div, @view.capture_haml { yield }, class: 'indent')

    nil
  end

  def render_input_field(params = {})
    populate_params!(params)

    if params[:setting_template].present?
      params[:setting_template].symbolize_keys!
      opts = { kit: @kit, params: params }
      if params[:partial]
        @view.render("kits/inputs/#{params[:partial]}", opts)
      else
        case params[:setting_template][:type]
        when 'boolean'
          if params[:setting_template][:values] && params[:setting_template][:values].many?
            @view.render('kits/inputs/check_box', opts)
          end
        when 'float'
          @view.render('kits/inputs/range', opts)
        when 'string', 'url'
          if params[:setting_template][:values] && params[:setting_template][:values].many?
            @view.render('kits/inputs/radios', opts)
          else
            @view.render('kits/inputs/string', opts)
          end
        else
          @view.render("kits/inputs/#{params[:setting_template][:type]}", opts)
        end
      end
    end
  end

  def addon_plan_settings
    _addon_plan_settings_record.template
  end

  private

  def load_settings
    load_settings_from_params || load_settings_from_kit
  end

  def load_settings_from_params
    if @view.params[:kit] && @view.params[:kit][:settings]
      @view.params[:kit][:settings]
    end
  end

  def load_settings_from_kit
    @kit.settings.symbolize_keys
  end

  def load_addon_plan
    @kit.site.addon_plan_for_addon_name(addon_name)
  end

  def populate_params!(params)
    params[:data]              ||= {}
    params[:addon]             ||= @addon_plan.addon
    params[:addon_plan_settings] ||= addon_plan_settings.symbolize_keys
    params[:setting_template]    = params[:addon_plan_settings][params[:setting_key].to_sym]
    params[:settings]            = @settings
    params[:setting]             = @settings[addon_name.to_sym][params[:setting_key].to_sym] rescue nil
    params[:value]               = get_value_from_params(params)
  end

  def get_value_from_params(params)
    params[:setting].nil? ? params[:setting_template][:default] : params[:setting]
  end

  def _addon_plan_settings_record
    @addon_plan.settings_for(@design)
  end

end
