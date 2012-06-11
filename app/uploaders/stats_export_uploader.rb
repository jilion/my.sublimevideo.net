require_dependency 's3_bucket'

class StatsExportUploader < CarrierWave::Uploader::Base
  include CarrierWave::MimeTypes

  process :set_content_type
  process :compress

  def fog_directory
    S3Bucket.stats_exports
  end

  def secure_url(*args)
    url = file.authenticated_url(*args)
    url.gsub!(/#{fog_directory}.s3.amazonaws.com/, "s3.amazonaws.com/#{fog_directory}")
    url
  end

  def fog_public
    false
  end

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    case Rails.env
    when 'production', 'staging'
      "stats_exports"
    else
      "uploads/stats_exports"
    end
  end

  def compress
    return if file.content_type == 'application/zip'
    cache_stored_file! if !cached?

    zip_path = current_path + '.zip'
    Zip::ZipFile.open(zip_path, Zip::ZipFile::CREATE) do |zipfile|
      zipfile.add(filename, current_path)
    end
    File.delete(current_path)

    store!(File.new(zip_path))
  end

  # Override the filename of the uploaded files
  def filename
    filename = "stats_export.#{model.st}.#{model.from.to_i}-#{model.to.to_i}.csv"
    filename += '.zip' if file.content_type == 'application/zip'
    filename
  end

end