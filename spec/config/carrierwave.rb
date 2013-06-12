require 'carrierwave'
require File.expand_path('config/initializers/carrierwave')
require 'carrierwave/test/matchers'

RSpec.configure do |config|
  config.include CarrierWave::Test::Matchers

  config.before :each, fog_mock: true do
    set_fog_configuration
  end
  config.before :all, type: :feature do
    set_fog_configuration
  end

  config.after :each, fog_mock: true do
    set_file_configuration
  end
  config.after :all, type: :feature do
    set_file_configuration
  end
end

def set_fog_configuration
  CarrierWave.fog_configuration
  Fog.mock!
  $fog_connection = Fog::Storage.new(
    provider:              'AWS',
    aws_access_key_id:     S3Wrapper.access_key_id,
    aws_secret_access_key: S3Wrapper.secret_access_key)
  S3Wrapper.buckets.each do |bucket_name, bucket|
    $fog_connection.directories.delete(key: bucket)
    $fog_connection.directories.create(key: bucket)
  end
end

def set_file_configuration
  CarrierWave.file_configuration
end
