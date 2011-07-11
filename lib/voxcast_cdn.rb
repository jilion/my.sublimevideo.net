# coding: utf-8

module VoxcastCDN
  # class DownloadError < StandardError; end

  class << self

    def devices_list
      client.voxel_devices_list
    end

    def purge(paths)
      client.voxel_voxcast_ondemand_content_purge_file(:device_id => yml[:device_id], :paths => parse_paths(paths))
    end

    def purge_dir(paths)
      client.voxel_voxcast_ondemand_content_purge_directory(:device_id => yml[:device_id], :paths => parse_paths(paths))
    end

    def verify(path)
      client.voxel_voxcast_ondemand_testing_get_url_per_pop(:device_id => yml[:device_id], :path => path)
    end

    def fetch_logs_names(hostnames = yml[:hostnames].split(', '))
      logs_names = []
      hostnames.each do |hostname_to_retrieve_logs|
        logs_hash = client.voxel_voxcast_ondemand_logs_list(:hostname => hostname_to_retrieve_logs, :device_id => yml[:device_id])
        if logs_hash['log_files']['sites']['hostname']['log_file'].present?
          logs_names += logs_hash['log_files']['sites']['hostname']['log_file'].map { |l| l['content'] }
        end
      end
      logs_names
    end

    def download_log(filename)
      xml = client.voxel_voxcast_ondemand_logs_download(:filename => filename)
      tempfile = Tempfile.new('log', "#{Rails.root}/tmp", :encoding => 'ASCII-8BIT')
      tempfile.write(Base64.decode64(xml['data']['content']))
      tempfile.flush
      tempfile
    rescue VoxelHAPI::Backend => ex
      ex.to_s =~ /log file not found/ ? false : raise(ex)
    end
    
    def non_ssl_hostname
      yml[:non_ssl_hostname]
    end
    def ssl_hostname
      yml[:ssl_hostname]
    end

  private

    def client
      @@client ||= VoxelHAPI.new(:hapi_authkey => { :key => yml[:key], :secret => yml[:secret] })
    end

    def yml
      config_path = Rails.root.join('config', 'voxcast_cdn.yml')
      @default_storage ||= YAML::load_file(config_path)
      @default_storage.to_options
    rescue
      raise StandardError, "VoxcastCDN config file '#{config_path}' doesn't exist."
    end

    def parse_paths(paths)
      paths.is_a?(Array) ? paths.join('\n') : paths
    end
  end
end