# coding: utf-8
class KitExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Kit'
  end

  def label
    "#{self.name}#{self.default? ? ' (Default)' : ''} - id: #{self.identifier}"
  end

  def render_name_as_link(template, site)
    title = self.default? ? 'This player will be displayed if no player is specified in your <video> tag.' : nil

    template.link_to template.edit_site_kit_path(site, self), title: title, class: 'name' do
      label
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

  def render_input_field(template, params = {})
    params[:setting_template]  = params[:settings_template][params[:setting_key]]
    params[:settings] = self.settings
    params[:setting]  = self.settings[params[:addon].name][params[:setting_key]] rescue nil

    if params[:setting_template].present?
      if params[:partial]
        template.render("kits/inputs/#{params[:partial]}", kit: self, params: params)
      else
        case params[:setting_template][:type]
        when 'boolean'
          if params[:setting_template][:values].many?
            template.render('kits/inputs/check_box', kit: self, params: params)
          end
        when 'float'
          template.render('kits/inputs/range', kit: self, params: params)
        when 'string'
          if params[:setting_template][:values].many?
            template.render('kits/inputs/radios', kit: self, params: params)
          end
        when 'url'
          template.render('kits/inputs/text', kit: self, params: params)
        when 'image'
          template.render('kits/inputs/image', kit: self, params: params)
        when 'size'
          if params[:setting_key] =~ /width\z/
            template.render('kits/inputs/size', kit: self, params: params)
          end
        end || ''
      end
    end
  end

  def eql?(other)
    (self.class == other.class) && (self.to_model == other.to_model)
  end
  alias :== eql?

end
