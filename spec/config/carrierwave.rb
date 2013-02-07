require 'carrierwave'
require File.expand_path('config/initializers/carrierwave')
require 'carrierwave/test/matchers'

RSpec.configure do |config|
  config.include CarrierWave::Test::Matchers

  config.before :each, fog_mock: true do
    set_fog_configuration
  end
  config.before :all, type: :request do
    set_fog_configuration
  end

  config.after :each, fog_mock: true do
    set_file_configuration
  end
  config.after :all, type: :request do
    set_file_configuration
  end
end

def set_fog_configuration
  CarrierWave.fog_configuration
  Fog::Mock.reset
  Fog.mock!
  Fog.credentials = {
    provider:              'AWS',
    aws_access_key_id:     S3.access_key_id,
    aws_secret_access_key: S3.secret_access_key,
    region:                'us-east-1'
  }
  $fog_connection = Fog::Storage.new(provider: 'AWS')
  S3.buckets.each do |bucket_name, bucket|
    $fog_connection.directories.create(key: bucket)
  end
end

def set_file_configuration
  CarrierWave.file_configuration
end
