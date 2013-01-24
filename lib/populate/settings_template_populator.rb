require_dependency 'populate/populator'
require 'active_support/core_ext'

class SettingsTemplatePopulator < Populator

  SETTINGS_TEMPLATES_DIR = Rails.root.join('lib/populate/settings_templates')

  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes
    set_template
  end

  def execute
    @settings_template_record = App::SettingsTemplate.create(@attributes, without_protection: true)
  end

  def set_template
    @attributes[:template] ||= begin
      path_parts = [@attributes[:addon_plan].addon.name, @attributes[:addon_plan].name]
      template = begin
        YAML.load_file(full_yml_path(path_parts, @attributes.delete(:suffix)))
      rescue TypeError
        {}
      end
      template.symbolize_keys
    end
  end

  def to_s
    @attributes.inspect
  end

  private

  def full_yml_path(path_parts, suffix = nil)
    yml_template_path = SETTINGS_TEMPLATES_DIR.join(yml_path(path_parts, suffix))

    if File.exists?(yml_template_path)
      yml_template_path
    else
      path_parts.pop
      if path_parts.any?
        full_yml_path(path_parts, suffix)
      end
    end
  end

  def yml_path(path_parts, suffix = nil)
    [path_parts.join('/'), suffix, 'template.yml'].compact.join('_')
  end

end
