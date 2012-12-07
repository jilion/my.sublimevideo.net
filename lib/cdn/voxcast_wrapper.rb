# coding: utf-8
require_dependency 'configurator'
require 'tempfile'

module CDN
  module VoxcastWrapper
    include Configurator

    config_file 'voxcast.yml'
    config_accessor :key, :secret, :device_id, :non_ssl_hostname, :ssl_hostname

    class << self

      def purge(path)
        if ::File.extname(path).present?
          purge_path(path)
        else
          purge_dir(path)
        end
        Librato.increment 'cdn.purge', source: 'voxcast'
      end

      def purge_path(path)
        rescue_and_retry(2, Timeout::Error) do
          client.voxel_voxcast_ondemand_content_purge_file(device_id: device_id, paths: path)
        end
      end

      def purge_dir(dir)
        rescue_and_retry(2, Timeout::Error) do
          client.voxel_voxcast_ondemand_content_purge_directory(device_id: device_id, paths: dir)
        end
      end

      def logs_list(hostname)
        rescue_and_retry(2) do
          logs = client.voxel_voxcast_ondemand_logs_list(device_id: device_id, hostname: hostname)
          logs["log_files"]["sites"]["hostname"]["log_file"]
        end
      end

      def download_log(filename)
        rescue_and_retry(2) do
          xml = client.voxel_voxcast_ondemand_logs_download(filename: filename)
          tempfile = Tempfile.new('log', Rails.root.join('tmp'), encoding: 'ASCII-8BIT')
          tempfile.write(Base64.decode64(xml['data']['content']))
          tempfile.flush
          tempfile
        end
      rescue VoxelHAPI::Backend => ex
        ex.to_s =~ /log file not found/ ? false : raise(ex)
      end

    private

      def client
        @client ||= VoxelHAPI.new(hapi_authkey: { key: key, secret: secret })
      end

    end

  end
end
