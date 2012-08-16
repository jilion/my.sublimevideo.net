require_dependency 'configurator'

module S3Bucket
  include Configurator

  config_file 's3_bucket.yml'
end
