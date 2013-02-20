require 'tempfile'
require 'cocaine'

module Addons
  class CustomLogoUploader

    MAX_SIZE = '"400x400>"'
    attr_reader :kit, :custom_logo, :old_custom_logo_path

    delegate :site, to: :kit
    delegate :upload!, :delete!, :present?, to: :cdn_file

    def initialize(kit, custom_logo, old_custom_logo_path = nil)
      @kit                  = kit
      @custom_logo          = custom_logo
      @old_custom_logo_path = old_custom_logo_path
    end

    def file
      @file ||= generate_file
    end

    def cdn_file
      @cdn_file ||= CDNFile.new(file.path, path, s3_headers)
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

    def path
      @path ||= "a/#{site.token}/#{kit.identifier}/logo-custom-#{width}x#{height}-#{Time.now.to_i}@2x.png"
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

    def s3_headers
      {
        'Cache-Control' => 's-maxage=7200, max-age=3600, public', # 2 hours / 1 hour
        'Content-Type'  => 'image/png',
        'x-amz-acl'     => 'public-read'
      }
    end
  end
end
