class LicenseUploader < CarrierWave::Uploader::Base
  include CarrierWave::MimeTypes

  process :set_content_type

  def s3_bucket
    S3Bucket.licenses
  end

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    case Rails.env
    when 'production', 'staging'
      "licenses"
    else
      "uploads/licenses"
    end
  end

  # Override the filename of the uploaded files
  def filename
    "#{model.token}.js" if original_filename
  end

end
