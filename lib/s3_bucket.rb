class S3Bucket < Settingslogic
  source "#{Rails.root}/config/s3_bucket.yml"
end

# module S3Bucket
#   class << self
#     
#     def method_missing(name)
#       yml[name.to_sym]
#     end
#     
#     def yml
#       config_path = Rails.root.join('config', 's3_bucket.yml')
#       @yml_options ||= YAML::load_file(config_path)[Rails.env]
#       @yml_options.to_options
#     rescue
#       raise StandardError, "S3 buckets config file '#{config_path}' doesn't exist."
#     end
#     
#   end
# end