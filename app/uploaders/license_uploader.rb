# encoding: utf-8

class LicenseUploader < CarrierWave::Uploader::Base
  
  def s3_bucket
    "sublimevideo.js"
  end
  
  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "js"
  end
  
  # Override the filename of the uploaded files
  def filename
    "#{model.token}.js" if original_filename
  end
  
end