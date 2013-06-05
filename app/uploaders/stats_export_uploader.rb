class StatsExportUploader < CarrierWave::Uploader::Base
  include CarrierWave::MimeTypes

  process :set_content_type
  process :compress

  def fog_directory
    S3Wrapper.buckets[:stats_exports]
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
    Rails.env.test? ? 'uploads/stats_exports' : 'stats_exports'
  end

  def compress
    return if file.content_type == 'application/zip'

    cache_stored_file! unless cached?

    zip_path = current_path + '.zip'
    Zip::ZipFile.open(zip_path, Zip::ZipFile::CREATE) do |zipfile|
      zipfile.add(filename, current_path)
    end
    File.delete(current_path)

    store!(File.new(zip_path))
  end

  # Override the filename of the uploaded files
  def filename
    filename = "stats_export.#{model.site_hostname}.#{model.from.strftime('%Y%m%d')}-#{model.to.strftime('%Y%m%d')}.csv"
    filename += '.zip' if file.content_type == 'application/zip'
    filename
  end

end
