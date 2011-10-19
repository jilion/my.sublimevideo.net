# coding: utf-8
module VoxcastCDN
  include Configurator

  heroku_config_file 'voxcast_cdn.yml'

  heroku_config_accessor '', :key, :secret, :device_id, :non_ssl_hostname, :ssl_hostname

  class << self

    def devices_list
      client.voxel_devices_list
    end

    def purge(paths)
      client.voxel_voxcast_ondemand_content_purge_file(device_id: device_id, paths: parse_paths(paths))
    end

    def purge_dir(paths)
      client.voxel_voxcast_ondemand_content_purge_directory(device_id: device_id, paths: parse_paths(paths))
    end

    def verify(path)
      client.voxel_voxcast_ondemand_testing_get_url_per_pop(device_id: device_id, path: path)
    end

    def download_log(filename)
      rescue_and_retry(7) do
        xml = client.voxel_voxcast_ondemand_logs_download(:filename => filename)
        tempfile = Tempfile.new('log', Rails.root.join('tmp'), :encoding => 'ASCII-8BIT')
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

    def parse_paths(paths)
      paths.is_a?(Array) ? paths.join('\n') : paths
    end

  end

end
