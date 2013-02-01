class KitSettingPresenter
  attr_accessor :addon_plan

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
    @addon_plan = @kit.site.addon_plan_for_addon_name(addon_name)
  end

  def viable?
    @addon_plan && any_settings?
  end

  def any_settings?
    !_settings_template_record.nil?
  end

  def settings_template_has_key?(key)
    settings_template.key?(key.to_sym)
  end

  def render_master_input_field(params = {}, &block)
    params[:data] ||= {}
    params[:data][:master] = "#{@addon_plan.addon.name}-#{params[:setting_key]}"

    @view.haml_concat(render_input_field(params))
    @view.haml_tag('div', @view.capture_haml { yield }, class: 'indent', data: { dependant: params[:data][:master] })

    nil
  end

  def render_input_field(params = {})
    populate_params!(params)

    if params[:setting_template].present?
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

  def settings_template
    _settings_template_record.template
  end

  private

  def populate_params!(params)
    params[:data]              ||= {}
    params[:addon]             ||= @addon_plan.addon
    params[:settings_template] ||= settings_template.symbolize_keys
    params[:setting_template]    = params[:settings_template][params[:setting_key].to_sym]
    params[:settings]            = @kit.settings.symbolize_keys
    params[:setting]             = @kit.settings[@addon_plan.addon.name][params[:setting_key].to_sym] rescue nil
    params[:value]               = get_value_from_params(params)
  end

  def get_value_from_params(params)
    case params[:setting_template][:type]
    when 'array'
      params[:setting] || params[:setting_template][:default].join(' ')
    else
      params[:setting] || params[:setting_template][:default] || ''
    end
  end

  def addon_name
    @addon_name_from_view ||= @view.view_renderer.instance_variable_get('@_partial_renderer').instance_values['path'].sub(%r{.+/(\w+)_settings}, '\1')
  end

  def _settings_template_record
    @addon_plan.settings_template_for(@design)
  end

end
