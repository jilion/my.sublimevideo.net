class KitExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Kit'
  end

  def render_settings_input_fields(addon_plan, template)
    if settings_template = addon_plan.settings_template_for(self.design) and settings_template.template
      if settings_template.editable?
        html = settings_template.template.inject('') do |html, (setting_key, setting_fields)|
          html += self.render_input_field(addon_plan.addon, setting_key, setting_fields, template)
          html
        end.html_safe
        html = template.content_tag(:h3, I18n.t("kit.#{addon_plan.addon.name}.title")) + html if html.present?
        html += template.content_tag(:div, '', class: %w[big_break spacer])
        html.html_safe
      end
    end
  end

  def render_input_field(addon, key, setting_fields, template)
    setting_fields = eval setting_fields
    settings = eval self.settings.try(:[], addon.id.to_s) || '{}'
    default = setting_fields[:default]

    case setting_fields[:values]
    when [0, 1]
      template.render('kits/inputs/check_box', kit: self, addon: addon, key: key, settings: settings, default: default)
    when 'float_0_1'
      template.render('kits/inputs/range', kit: self, addon: addon, key: key, in_range: (0..1), step: 0.05, settings: settings, default: default)
    when Array
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
