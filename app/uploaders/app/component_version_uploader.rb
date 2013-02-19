class App::ComponentVersionUploader < CarrierWave::Uploader::Base
  include CarrierWave::MimeTypes

  process :set_content_type

  before :store, :store_zip_content
  before :remove, :remove_zip_content

  def fog_directory
    S3Wrapper.buckets['player']
  end

  def fog_public
    false
  end

  # Override the directory where uploaded files will be stored
  # # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    Rails.env.test? ? "uploads/app/c" : "c"
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(zip)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "#{model.name}-#{model.version_for_url}.zip" if original_filename
  end

  def store_zip_content(new_file)
    # new_file not used because nil
    zip_content_uploader.store_zip_content(file.path)
  end

  def remove_zip_content
    zip_content_uploader.remove_zip_content
  end

  def zip_content_uploader
    upload_path = Pathname.new("c/#{model.token}/#{model.version}/")
    App::ComponentVersionZipContentUploader.new(upload_path)
  end
end
