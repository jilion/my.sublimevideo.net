require_dependency 'custom/carrierwave/mime_types'
require_dependency 's3_bucket'

class LoaderUploader < CarrierWave::Uploader::Base
  include CarrierWave::MimeTypes
  include Custom::CarrierWave::MimeTypes

  process :set_content_type

  def fog_directory
    S3Bucket.loaders
  end

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    case Rails.env
    when 'production', 'staging'
      "loaders"
    else
      "uploads/loaders"
    end
  end

  # Override the filename of the uploaded files
  def filename
    "#{model.token}.js" if original_filename
  end

end
