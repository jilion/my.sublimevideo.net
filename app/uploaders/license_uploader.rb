class LicenseUploader < CarrierWave::Uploader::Base
  
  def s3_bucket
    Rails.env.production? ? "sublimevideo.licenses" : "sublimevideo.licenses" # TODO Change for dev
  end
  
  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if Rails.env.production?
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