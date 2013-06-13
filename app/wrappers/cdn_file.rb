require 's3_wrapper'

class CDNFile
  attr_accessor :file, :path, :headers

  def initialize(file, path, headers)
    @file = file
    @path = path
    @headers = headers
  end

  def upload!
    File.open(file) do |f|
      data = f.read
      S3Wrapper.fog_connection.put_object(bucket, path, data, headers)
    end
  end

  def delete!
    S3Wrapper.fog_connection.delete_object(bucket, path)
  end

  def present?
    s3_headers.present?
  end

  def bucket
    @bucket ||= S3Wrapper.buckets[:sublimevideo]
  end

  private

  def s3_headers
    S3Wrapper.fog_connection.head_object(bucket, path).headers
  rescue Excon::Errors::NotFound
    {}
  end
end
