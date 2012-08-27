require_dependency 'custom/carrierwave/mime_types'
require_dependency 's3'

class LicenseUploader < CarrierWave::Uploader::Base
  include CarrierWave::MimeTypes
  include Custom::CarrierWave::MimeTypes

  process :set_content_type

  def fog_directory
    S3.buckets['licenses']
  end

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    Rails.env.test? ? "uploads/licenses" : "licenses"
  end

  # Override the filename of the uploaded files
  def filename
    "#{model.token}.js" if original_filename
  end

end
