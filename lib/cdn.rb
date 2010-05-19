module CDN
  class << self
    def devises_list
      client.voxel_devices_list
    end
    
    def populate(paths)
      client.voxel_voxcast_ondemand_content_populate(:device_id => yml[:device_id], :paths => parse_paths(paths))
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
    
    def logs_list(hostname = 'cdn.sublimevideo.net')
      client.voxel_voxcast_ondemand_logs_list(:device_id => yml[:device_id], :hostname => hostname)
    end
    
    def logs_download(filename)
      xml = client.voxel_voxcast_ondemand_logs_download(:filename => filename)
      tempfile = Tempfile.new('log', "#{Rails.root}/tmp")
      tempfile.write(Base64.decode64(xml['data']['content'])) 
      tempfile.flush
    end
    
  private
    
    def client
      @client ||= HAPI.new(:hapi_authkey => { :key => yml[:key], :secret => yml[:secret] })
    end
    
    def yml
      config_path = File.join(Rails.root, 'config', 'cdn.yml')
      @default_storage ||= YAML::load_file(config_path)
      @default_storage.to_options
    rescue
      raise StandardError, "CDN config file '#{config_path}' doesn't exist."
    end
    
    def parse_paths(paths)
      paths = paths.join('\n') if paths.is_a?(Array)
      paths
    end
  end
end