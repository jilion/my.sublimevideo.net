require 'active_support/core_ext'

module Configurator
  extend ActiveSupport::Concern

  included do
    class << self
      attr_accessor :config_path, :prefix
    end
  end

  module ClassMethods

    def config_file(filename, options = {})
      @config_path = Rails.root.join('config', filename)
      @config_file_options = { rails_env: true }.merge(options)
      @prefix = File.basename(filename, '.yml').upcase
    end

    def config_accessor(*attributes)
      @config_attributes = attributes
    end

    def method_missing(*args)
      method_name = args.shift.to_sym

      if @config_attributes && @config_attributes.include?(method_name)
        yml_options[method_name] == 'env_var' ? ENV["#{@prefix}_#{method_name.to_s.upcase}"] : yml_options[method_name]
      else
        yml_options[method_name].nil? ? super(method_name, *args) : yml_options[method_name]
      end
    end

    def respond_to?(*args)
      method_name = args.shift.to_sym

      (@config_attributes || []).include?(method_name) || yml_options[method_name] || super(method_name, args)
    end

    def yml_options
      if Rails.env == 'test'
        calculate_yml_options
      else
        @yml_options ||= calculate_yml_options
      end
    end

    private

    def calculate_yml_options
      yml_hash = if @config_file_options[:rails_env]
        YAML.load_file(@config_path)[Rails.env.to_s]
      else
        YAML.load_file(@config_path)
      end
      HashWithIndifferentAccess.new(yml_hash)
    end

  end
end
