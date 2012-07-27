module Configurator
  extend ActiveSupport::Concern

  included do
    class << self
      attr_accessor :config_path, :prefix
    end
  end

  module ClassMethods

    def heroku_config_file(filename)
      @config_path = Rails.root.join('config', filename)
    end

    def heroku_config_accessor(prefix, *attributes)
      @prefix = prefix
      @heroku_config_attributes = attributes
    end

    def method_missing(*args)
      method_name = args.shift.to_sym

      if @heroku_config_attributes && @heroku_config_attributes.include?(method_name)
        yml_options[method_name] == 'heroku_env' ? ENV["#{@prefix.to_s.upcase}_#{method_name.to_s.upcase}"] : yml_options[method_name]
      else
        yml_options[method_name].nil? ? super(method_name, *args) : yml_options[method_name]
      end
    end

    def respond_to?(*args)
      method_name = args.shift.to_sym

      (@heroku_config_attributes || []).include?(method_name) || yml_options[method_name] || super(method_name, args)
    end

    def reset_yml_options
      @yml_options = nil
    end

    def yml_options
      @yml_options ||= YAML.load_file(@config_path)[Rails.env]
      @yml_options.symbolize_keys
    end

  end

end
