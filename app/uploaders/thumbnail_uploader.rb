# encoding: utf-8

class ThumbnailUploader < CarrierWave::Uploader::Base
  
  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "t/#{model.token}"
  end
  
  # Override the filename of the uploaded files
  # def filename
  #   "#{model.token}.js" if original_filename
  # end
  
end