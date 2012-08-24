require_dependency 's3'

class Player::BundleVersionUploader < CarrierWave::Uploader::Base
  include CarrierWave::MimeTypes

  process :set_content_type
  process :store_zip_content

  after :remove, :remove_zip_content

  def fog_directory
    S3.buckets['player']
  end

  def fog_public
    false
  end

  # Override the directory where uploaded files will be stored
  # # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    case Rails.env
    when 'production', 'staging'
      "b"
    else
      "uploads/player/b"
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(zip)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "#{model.name}-#{model.version}.zip" if original_filename
  end

  def store_zip_content
    Player::BundleVersionZipContentUploader.store_zip_content(file.path, zip_content_upload_path)
  end

  def remove_zip_content
    Player::BundleVersionZipContentUploader.remove_zip_content(zip_content_upload_path)
  end

  def zip_content_upload_path
    Pathname.new("b/#{model.token}/#{model.version}")
  end

end
