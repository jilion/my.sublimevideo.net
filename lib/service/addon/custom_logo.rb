require 'tempfile'
require_dependency 'cdn/file'

module Service
  module Addon
    CustomLogo = Struct.new(:custom_logo) do

      attr_accessor :file, :cdn_file

      delegate :kit, :site, to: :custom_logo
      delegate :upload!, :delete!, :present?, to: :cdn_file

      def initialize(*args)
        super
        @file = generate_file
        @cdn_file = CDN::File.new(
          @file.path,
          destinations,
          s3_options
        )
      end

      private

      def generate_file
        # TODO Remy:
        # - resizing (image magick)
        # - compressing (image magick)
        custom_logo.file
      end

      def destinations
        [{
          bucket: S3.buckets['sublimevideo'],
          path: custom_logo.path
        }]
      end

      def s3_options
        {
          'Cache-Control' => 'max-age=60, public', # 1 minutes
          'Content-Type'  => 'image/png',
          'x-amz-acl'     => 'public-read'
        }
      end

    end
  end
end
