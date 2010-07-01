class VideoUploader < CarrierWave::Uploader::Base
  
  def s3_bucket
    Rails.env.production? ? "sublimevideo.videos" : "dev.sublimevideo.videos"
  end
  
  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if Rails.env.production?
      "#{model.video.token}"
    else
      "uploads/videos/#{model.video.token}"
    end
  end
  
  # Override the filename of the uploaded files
  def filename
    "#{model.video.name}#{model.profile.name}.#{model.extname}" if original_filename
  end
  
end