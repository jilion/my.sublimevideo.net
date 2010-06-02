module Trial
  
  def self.method_missing(name)
    yml[name.to_sym]
  end
  
private
  
  def self.yml
    config_path = Rails.root.join('config', 'trial.yml')
    @yml ||= YAML::load_file(config_path).to_options
  rescue
    raise StandardError, "Trial config file '#{config_path}' doesn't exist."
  end
  
end
