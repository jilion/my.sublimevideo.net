class ReleaseUploader < CarrierWave::Uploader::Base
  
  def s3_bucket
    S3Bucket.player
  end
  
  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    Rails.env.test? ? "uploads/releases" : "releases"
  end
  
  # Add a white list of extensions which are allowed to be uploaded,
  # for images you might use something like this:
  def extension_white_list
    %w(zip)
  end
  
  # Override the filename of the uploaded files
  def filename
    "#{model.date}-#{model.token}.zip" if original_filename
  end
  
end
