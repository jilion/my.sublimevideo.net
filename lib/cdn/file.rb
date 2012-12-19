require 's3etag'
require_dependency 'cdn'

module CDN
  File = Struct.new(:file, :destinations, :s3_options, :options) do

    def upload!
      # if changed?
      ::File.open(file) do |f|
        data = f.read
        destinations.each do |destination|
          S3.fog_connection.put_object(
            destination[:bucket],
            destination[:path],
            data,
            s3_options
          )
        end
      end
        # true
      # end
    end

    def delete!
      # if present?
      destinations.each do |destination|
        S3.fog_connection.delete_object(
          destination[:bucket],
          destination[:path]
        )
      end
        # true
      # end
    end

    # file already present on S3?
    def present?
      destinations.all? do |destination|
        s3_headers(
          destination[:bucket],
          destination[:path]
        ).present?
      end
    end

    # # file different that the one already present on S3?
    # def changed?
    #   etag != uploaded_etag
    # end

    private

    # def etag
    #   S3Etag.calc(file: file)
    # end

    # def uploaded_etag
    #   destination = destinations.first
    #   headers = s3_headers(
    #     destination[:bucket],
    #     destination[:path]
    #   )
    #   headers['ETag'] && headers['ETag'].gsub('"','').strip
    # end

    def s3_headers(bucket, path)
      S3.fog_connection.head_object(
        bucket,
        path
      ).headers
    rescue Excon::Errors::NotFound
      {}
    end

  end
end unless defined? CDN::File
