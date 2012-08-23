require_dependency 's3'
require_dependency 'file_header'

class Player::BundleVersionZipContentUploader

  def self.upload_zip_content(zip_path, upload_path)
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

private

  def self.put_object(object_name, data, options = {})
    fog_connection.put_object(
      S3.buckets['sublimevideo'],
      object_name,
      data,
      options
    )
  end

  def self.fog_connection
    @fog_connection ||= Fog::Storage.new(
      provider:              'AWS',
      aws_access_key_id:     S3.access_key_id,
      aws_secret_access_key: S3.secret_access_key,
      region:                'us-east-1'
    )
  end

end
