require 'carrierwave/test/matchers'

RSpec.configure do |config|
  config.include CarrierWave::Test::Matchers

  config.before :each, fog_mock: true do
    CarrierWave.fog_configuration
    Fog.mock!
    Fog.credentials = {
      provider:              'AWS',
      aws_access_key_id:     S3.access_key_id,
      aws_secret_access_key: S3.secret_access_key,
      region:                'us-east-1'
    }
    unless $fog_connection
      $fog_connection = Fog::Storage.new(:provider => 'AWS')
      %w[licenses loaders player logs stats_exports].each do |bucket|
        $fog_connection.directories.create(:key => S3Bucket.send(bucket) )
      end
    end
  end

  config.after :each, fog_mock: true do
    CarrierWave.file_configuration
  end
end
