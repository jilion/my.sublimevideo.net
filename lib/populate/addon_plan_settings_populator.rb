class AddonPlanSettingsPopulator < Populator

  SETTINGS_DIR = Rails.root.join('lib/populate/addon_plans_settings')

  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes
    set_template
  end

  def execute
    @addon_plan_settings_record = AddonPlanSettings.create(@attributes)
  end

  def set_template
    @attributes[:template] ||= begin
      path_parts = [@attributes[:addon_plan].addon_name, @attributes[:addon_plan].name]
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
    yml_template_path = SETTINGS_DIR.join(yml_path(path_parts, suffix))

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
