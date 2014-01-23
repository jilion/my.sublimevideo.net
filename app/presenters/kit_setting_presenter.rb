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

  def render_master_input_field(parameters = {}, &block)
    @view.haml_concat(render_input_field(parameters))
    @view.haml_tag(:div, @view.capture_haml { yield }, class: 'indent')

    nil
  end

  def render_input_field(parameters = {})
    parameters = populate_parameters(parameters)

    if parameters[:setting_template].present?
      opts = { kit: @kit, parameters: parameters }
      if parameters[:partial]
        @view.render("kits/inputs/#{parameters[:partial]}", opts)
      else
        case parameters[:setting_template][:type]
        when 'boolean'
          if parameters[:setting_template][:values] && parameters[:setting_template][:values].many?
            @view.render('kits/inputs/check_box', opts)
          end
        when 'float'
          @view.render('kits/inputs/range', opts)
        when 'string', 'url'
          if parameters[:setting_template][:values] && parameters[:setting_template][:values].many?
            @view.render('kits/inputs/radios', opts)
          else
            @view.render('kits/inputs/string', opts)
          end
        else
          @view.render("kits/inputs/#{parameters[:setting_template][:type]}", opts)
        end
      end
    end
  end

  def addon_plan_settings
    _addon_plan_settings_record.template
  end

  private

  def load_settings
    load_settings_from_kit
  end

  def load_settings_from_kit
    @kit.settings.symbolize_keys
  end

  def load_addon_plan
    @kit.site.addon_plan_for_addon_name(addon_name)
  end

  def populate_parameters(parameters)
    parameters = parameters.with_indifferent_access

    parameters[:data]                ||= {}
    parameters[:addon]               ||= @addon_plan.addon
    parameters[:addon_plan_settings] ||= addon_plan_settings.symbolize_keys
    parameters[:setting_template]      = parameters[:addon_plan_settings][parameters[:setting_key].to_sym]
    parameters[:settings]              = @settings
    parameters[:setting]               = @settings[addon_name.to_sym][parameters[:setting_key].to_sym] rescue nil
    parameters[:value]                 = get_value_from_parameters(parameters)

    parameters
  end

  def get_value_from_parameters(parameters)
    parameters[:setting].nil? ? parameters[:setting_template][:default] : parameters[:setting]
  end

  def _addon_plan_settings_record
    @addon_plan.settings_for(@design)
  end

end
