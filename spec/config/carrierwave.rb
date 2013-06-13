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
  Fog::Mock.reset
  Fog.mock!
  Fog.credentials = {
    provider:              'AWS',
    aws_access_key_id:     ENV['S3_ACCESS_KEY_ID'],
    aws_secret_access_key: ENV['S3_SECRET_ACCESS_KEY'],
    region:                'us-east-1'
  }
  $fog_connection = Fog::Storage.new(provider: 'AWS')
  S3Wrapper.buckets.each do |_, bucket|
    $fog_connection.directories.create(key: bucket)
  end
end

def set_file_configuration
  CarrierWave.file_configuration
end
