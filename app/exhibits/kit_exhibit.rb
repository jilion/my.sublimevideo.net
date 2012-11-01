class KitExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Kit'
  end

  def render_name_as_link(template, site)
    kit_is_default = self == site.default_kit
    title = kit_is_default ? 'This player will be displayed if no player is specified in your <video> tag.' : nil

    template.link_to template.edit_site_kit_path(site, self), title: title, class: 'name' do
      self.name.titleize + (kit_is_default ? ' (Default)' : '')
    end
  end

  def render_settings_input_fields_for_addon(addon_name, template)
    render_settings_input_fields(site.addon_plan_for_addon_name(addon_name), template)
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

  def render_input_field(template, params = {})
    params[:template_settings] = params[:settings_template][params[:setting_key]]
    params[:settings] = self.settings[params[:addon].name][params[:setting_key]] rescue {}

    case params[:template_settings][:type]
    when 'boolean'
      if params[:template_settings][:values].many?
        template.render('kits/inputs/check_box', kit: self, params: params)
      end
    when 'float'
      template.render('kits/inputs/range', kit: self, params: params)
    when 'string'
      if (2..3).cover?(params[:template_settings][:values].size)
        template.render('kits/inputs/radio', kit: self, params: params)
      end
    when 'url'
      template.render('kits/inputs/text', kit: self, params: params)
    when 'size'
      if params[:setting_key] =~ /width\z/
        template.render('kits/inputs/size', kit: self, params: params)
      end
    end || ''
  end

  def eql?(other)
    (self.class == other.class) && (self.to_model == other.to_model)
  end
  alias :== eql?

end
