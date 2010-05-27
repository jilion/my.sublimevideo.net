class VideoUploader < CarrierWave::Uploader::Base
  
  def s3_bucket
    "sublimevideo.videos"
  end
  
  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    token = (model.class == VideoFormat) ? model.original.token : model.token
    if Rails.env.production?
      "/#{token}"
    else
      "uploads/v/#{token}"
    end
  end
  
  # Override the filename of the uploaded files
  # def filename
  #   "#{model.token}.js" if original_filename
  # end
  
end