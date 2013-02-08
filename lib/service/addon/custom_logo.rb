require 'tempfile'
require 'cocaine'

module Service
  module Addon
    CustomLogo = Struct.new(:kit, :custom_logo, :old_custom_logo_path) do

      self::MAX_SIZE = '"400x400>"'

      attr_accessor :file, :cdn_file

      delegate :site, to: :kit
      delegate :delete!, :present?, to: :cdn_file

      def initialize(*args)
        super
        @cdn_file = CDNFile.new(
          file.path,
          destinations,
          s3_options
        )
      end

      def upload!
        # CDNFile.new(nil, destinations(old_custom_logo_path), s3_options).delete!
        @cdn_file.upload!
      end

      def file
        @file ||= generate_file
      end

      def width
        size[0].to_i
      end

      def height
        size[1].to_i
      end

      def size
        line = Cocaine::CommandLine.new('identify', ':source')
        @size ||= begin
          line.run(source: File.expand_path(file.path)).split(' ')[2].split('x')
        rescue Cocaine::ExitStatusError => e
          Rails.logger.info e.message
          nil
        end
      end

      def current_path
        @current_path ||= "a/#{site.token}/#{kit.identifier}/logo-custom-#{width}x#{height}-#{Time.now.to_i}@2x.png"
      end

      private

      def generate_file
        processed_file = Tempfile.new('logo-custom@2x.png', Rails.root.join('tmp'))

        line = Cocaine::CommandLine.new('convert', [':source', '-scale', self.class::MAX_SIZE, ':destination'].join(' '))
        begin
          line.run(source: File.expand_path(custom_logo.file.path), destination: File.expand_path(processed_file.path))
        rescue Cocaine::ExitStatusError => e
          Rails.logger.info e.message
        end

        processed_file
      end

      def destinations(path = current_path)
        [{
          bucket: S3Wrapper.buckets['sublimevideo'],
          path: path
        }]
      end

      def s3_options
        {
          'Cache-Control' => 's-maxage=7200, max-age=3600, public', # 2 hours / 1 hour
          'Content-Type'  => 'image/png',
          'x-amz-acl'     => 'public-read'
        }
      end

    end
  end
end
