require 'digest/md5'
require_dependency 'cdn'

module CDN
  class File < Struct.new(:file, :destinations, :s3_options)

    def initialize(*args)
      super
    end

    def upload!
      if changed?
        ::File.open(file) do |f|
          data = f.read
          destinations.each do |destination|
            S3.fog_connection.put_object(
              destination[:bucket],
              destination[:path],
              data,
              s3_options.merge('Content-MD5' => md5)
            )
          end
        end
        purge_cdn
        true
      end
    end

    def delete!
      if present?
        destinations.each do |destination|
          S3.fog_connection.delete_object(
            destination[:bucket],
            destination[:path]
          )
        end
        purge_cdn
        true
      end
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

    # file different that the one already present on S3?
    def changed?
      md5 != uploaded_md5
    end

  private

    def md5
      ::File.open(file) { |f| Digest::MD5.base64digest(f.read) }
    end

    def uploaded_md5
      destination = destinations.first
      s3_headers(
        destination[:bucket],
        destination[:path]
      )['Content-MD5']
    end

    def s3_headers(bucket, path)
      S3.fog_connection.head_object(
        bucket,
        path
      ).headers
    rescue Excon::Errors::NotFound
      {}
    end

    def purge_cdn
      CDN.purge("/#{destinations.first[:path]}")
    end

  end
end
