class KitExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Kit'
  end

  def render_input_field(addon, key, setting_fields, template)
    setting_fields = eval setting_fields
    settings = eval self.settings[addon.id.to_s]
    default = setting_fields[:default]

    case setting_fields[:values]
    when 'bool'
      template.render('kits/inputs/check_box', kit: self, addon: addon, key: key, settings: settings, default: default)
    when 'float_0_1'
      template.render('kits/inputs/range', kit: self, addon: addon, key: key, in_range: (0..1), step: 0.1, settings: settings, default: default)
    when Array
      if setting_fields[:values].size <= 3
        template.render('kits/inputs/radio', kit: self, addon: addon, key: key, settings: settings, choices: setting_fields[:values], default: default)
      end
    end
  end

  def eql?(other)
    (self.class == other.class) && (self.to_model == other.to_model)
  end
  alias :== eql?

end
