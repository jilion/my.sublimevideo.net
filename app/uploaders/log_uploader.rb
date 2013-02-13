class LogUploader < CarrierWave::Uploader::Base
  include CarrierWave::MimeTypes

  process :set_content_type

  def fog_directory
    S3Wrapper.buckets['logs']
  end

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if Rails.env.test?
      "uploads/voxcast"
    else
      "voxcast"
    end
  end

  # Override the filename of the uploaded files
  def filename
    model.name if original_filename
  end

end
