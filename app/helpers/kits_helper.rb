module KitsHelper

  def formatted_kit_settings(kit)
    formatted_kits_settings(kit.site)[kit.identifier].to_json
  end

  def formatted_kits_settings(site)
    @formatted_kits_settings ||= SettingsFormatter.format(kits_settings(site))
  end

  def kits_settings(site)
    @kits_settings ||= SettingsGenerator.new(site).kits(true)
  end

  def designs_for_select(site, kit)
    items = site.designs.order(:id).reduce([]) do |a, e|
      a << [e.title, e.id, { 'data-preview-kit-id' => PreviewKit.kit_identifer(e.name) }]
    end

    options_for_select(items, kit.design_id)
  end

  def kit_settings_expanding_handler(name)
    id = "#{name}_handler"
    classes = ['expanding_handler']
    classes << 'expanded' if params[:expand] == id

    haml_tag("h4##{id}.#{classes.join('.')}", capture_haml { yield })
  end

  def kit_settings_expendable_block(name)
    handler_id = "#{name}_handler"
    classes = ['expandable']
    classes << 'expanded' if params[:expand] == handler_id

    haml_tag("div.#{classes.join('.')}", capture_haml { yield })
  end

  def kit_setting_title(params, suffix = '')
    t("kit.#{params[:addon].name}.settings.#{params[:translation_key] || params[:setting_key]}#{suffix}")
  end

  def kit_setting_radio_label(params, choice = '')
    t("kit.#{params[:addon].name}.values.#{params[:translation_key] || params[:setting_key]}.#{choice}")
  end

  def kit_setting_input_field_name(params, suffix = '')
    "kit[settings][#{params[:addon].name}][#{params[:setting_key]}]#{suffix}"
  end

  def kit_setting_input_field_id(params, suffix = '')
    "kit_setting-#{params[:addon].name}-#{params[:setting_key]}#{suffix}"
  end

  def kit_setting_data(params)
    params[:data].merge(addon: params[:addon].kind, setting: params[:setting_key], default: params[:value])
  end

  def kits_for_select(site)
    items = site.kits.includes(:design).order(:identifier).reduce([]) do |a, e|
      a << [e.name, e.identifier, { 'data-preview-kit-id' => PreviewKit.kit_identifer(e.design.name) }]
    end

    options_for_select(items, site.default_kit.identifier)
  end

  def display_custom_logo(url)
    return if url.blank?

    if matches = url.match(/-(\d+)x(\d+)-\d+@/)
      tag(:img, src: url, width: matches[1].to_i / 2, height: matches[2].to_i / 2)
    end
  end

end
