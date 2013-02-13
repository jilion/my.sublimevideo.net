require 's3etag'

CDNFile = Struct.new(:file, :destinations, :s3_options, :options) do

  def upload!
    File.open(file) do |f|
      data = f.read
      destinations.each do |destination|
        S3Wrapper.fog_connection.put_object(
          destination[:bucket],
          destination[:path],
          data,
          s3_options
        )
      end
    end
  end

  def delete!
    destinations.each do |destination|
      S3Wrapper.fog_connection.delete_object(
        destination[:bucket],
        destination[:path]
      )
    end
  end

  # file already present on S3Wrapper?
  def present?
    destinations.all? do |destination|
      s3_headers(
        destination[:bucket],
        destination[:path]
      ).present?
    end
  end

  private

  def s3_headers(bucket, path)
    S3Wrapper.fog_connection.head_object(
      bucket,
      path
    ).headers
  rescue Excon::Errors::NotFound
    {}
  end

end
