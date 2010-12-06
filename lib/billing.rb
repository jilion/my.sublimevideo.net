class Billing < Settingslogic
  source "#{Rails.root}/config/billing.yml"
end
# module Billing
#   class << self
#     
#     def method_missing(name)
#       yml[name.to_sym]
#     end
#     
#     def reset_yml_options
#       @yml_options = nil
#     end
#     
#   private
#     
#     def yml
#       config_path = Rails.root.join('config', 'billing.yml')
#       @yml_options ||= YAML::load_file(config_path)
#       @yml_options.to_options
#     rescue
#       raise StandardError, "Billing config file '#{config_path}' doesn't exist."
#     end
#     
#   end
# end