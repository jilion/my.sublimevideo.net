class KitExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Kit'
  end

  def render_grouped_settings_input_fields(addon_plans, template)
    first_inputs = render_settings_input_fields(addon_plans.shift, template, show_break: false)
    last_inputs  = render_settings_input_fields(addon_plans.pop, template, show_title: false)
    between_inputs = addon_plans.inject('') do |html, addon_plan|
      html += render_settings_input_fields(addon_plan, template, show_title: false, show_break: false)
      html
    end.html_safe

    first_inputs + between_inputs + last_inputs
  end

  def render_settings_input_fields(addon_plan, template, options = {})
    if settings_template = addon_plan.settings_template_for(self.design) and settings_template.template
      options.reverse_merge!(show_title: true, show_break: true)

      html = settings_template.template.inject('') do |html, (setting_key, setting_fields)|
        html += self.render_input_field(addon_plan.addon, setting_key, setting_fields, template)
        html
      end.html_safe

      if html.present?
        html  = template.content_tag(:h3, I18n.t("kit.#{addon_plan.addon.name}.title")) + html if options[:show_title]
        html += template.content_tag(:div, '', class: %w[spacer] + (options[:show_break] ? %w[big_break] : []))
      end

      html.html_safe
    end
  end

  def render_input_field(addon, key, setting_fields, template)
    settings = self.settings.try(:[], addon.name) || {}
    default = setting_fields[:default]

    case setting_fields[:type]
    when 'boolean'
      if setting_fields[:values].many?
        template.render('kits/inputs/check_box', kit: self, addon: addon, key: key, settings: settings, default: default)
      end
    when 'float'
      template.render('kits/inputs/range', kit: self, addon: addon, key: key, in_range: setting_fields[:range], step: setting_fields[:step], settings: settings, default: default)
    when 'string'
      if (2..3).cover?(setting_fields[:values].size)
        template.render('kits/inputs/radio', kit: self, addon: addon, key: key, settings: settings, choices: setting_fields[:values], default: default)
      end
    end || ''
  end

  def eql?(other)
    (self.class == other.class) && (self.to_model == other.to_model)
  end
  alias :== eql?

end
