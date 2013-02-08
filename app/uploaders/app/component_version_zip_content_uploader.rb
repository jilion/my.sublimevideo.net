require_dependency 'file_header'

class App::ComponentVersionZipContentUploader

  def self.store_zip_content(zip_path, upload_path)
    Zip::ZipFile.foreach(zip_path) do |zipfile|
      next if zipfile.name =~ /__MACOSX|.DS_Store/ || zipfile.directory?
      object_name  = upload_path.join(zipfile.name).to_s
      content_type = FileHeader.content_type(zipfile.to_s)
      zipfile.get_input_stream do |io|
        put_object(object_name, io.read,
          'Cache-Control' => "max-age=29030400, public",
          'Content-Type'  => content_type,
          'x-amz-acl'     => 'public-read'
        )
      end
    end
  end

  def self.remove_zip_content(upload_path)
    S3Wrapper.fog_connection.directories.get(
      S3Wrapper.buckets['sublimevideo'],
      prefix: upload_path.to_s
    ).files.each { |file| file.destroy }
  end

private

  def self.put_object(object_name, data, options = {})
    S3Wrapper.fog_connection.put_object(
      S3Wrapper.buckets['sublimevideo'],
      object_name,
      data,
      options
    )
  end

end
