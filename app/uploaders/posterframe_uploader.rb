class PosterframeUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  
  version :thumb do
    process :resize_to_fill => [160,90]
  end
  
  def s3_bucket
    "sublimevideo.videos"
  end
  
  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if Rails.env.production?
      "#{model.token}"
    else
      "uploads/videos/#{model.token}"
    end
  end
  
  # Override the filename of the uploaded files
  def filename
    "posterframe.jpg" if original_filename
  end
  
  # def default_url
  #   [version_name, "default_posterframe.jpg"].compact.join('_')
  # end
  
end