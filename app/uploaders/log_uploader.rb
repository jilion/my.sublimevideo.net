class LogUploader < CarrierWave::Uploader::Base
  
  def s3_bucket
    S3Bucket.logs
  end
  
  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    case Rails.env
    when 'production', 'staging'
      model.class.config[:store_dir]
    else
      "uploads/#{model.class.config[:store_dir]}"
    end
  end
  
  # Override the filename of the uploaded files
  def filename
    model.name if original_filename
  end
  
end