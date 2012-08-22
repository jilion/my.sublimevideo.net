require_dependency 's3'

class Player::BundleVersionUploader < CarrierWave::Uploader::Base
  include CarrierWave::MimeTypes

  process :set_content_type
  process :upload_zip_content

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

  def upload_zip_content
    dir_path = Pathname.new("b/#{model.token}/#{model.version}")
    # Player::BundleZipCUploader.upload_zip_content(file, dir_path)
  end

    # def self.upload_zip_content(zip, path)
    #   Zip::ZipFile.foreach(zip) do |zipfile|
    #     next if zipfile.name =~ /__MACOSX|.DS_Store/
    #     object_path = path.join(zipfile.name)
    #     p zipfile.class
    #     p zipfile.size
    #     # zipfile.get_input_stream do |io|
    #       # puts io.size
    #       # fog_connection.put_object(S3.buckets['sublimevideo'], object_path.to_s, io.read)
    #     # end
    #   end
    # end

    # def self.fog_connection
    #   Fog::Storage.new(
    #     provider:              'AWS',
    #     aws_access_key_id:     S3.access_key_id,
    #     aws_secret_access_key: S3.secret_access_key,
    #     region:                'us-east-1'
    #   )
    # end


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

end
