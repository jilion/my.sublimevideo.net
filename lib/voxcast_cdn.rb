# coding: utf-8

module VoxcastCDN
  class << self
    def devices_list
      client.voxel_devices_list
    end

    # def populate(paths)
    #   client.voxel_voxcast_ondemand_content_populate(:device_id => yml[:device_id], :paths => parse_paths(paths))
    # end

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
      # FIX voxel.voxcast.ondemand.logs.list that seems to need a hostname now
      logs_names = []
      hostnames.each do |hostname_to_retrieve_logs|
        logs_hash = client.voxel_voxcast_ondemand_logs_list(:hostname => hostname_to_retrieve_logs, :device_id => yml[:device_id])
        if logs_hash['log_files']['sites']['hostname']['log_file'].present?
          logs_names.concat(logs_hash['log_files']['sites']['hostname']['log_file'].map { |l| l['content'] })
        end
      end
      logs_names
      # logs_hash = client.voxel_voxcast_ondemand_logs_list(:device_id => yml[:device_id])
      # logs_hash['log_files']['sites']['hostname'].inject([]) do |logs_names, hostname_logs_hash|
      #   if hostnames.include?(hostname_logs_hash['name']) && hostname_logs_hash['log_file'].present?
      #     logs_names += hostname_logs_hash['log_file'].map { |l| l['content'] }
      #   end
      #   logs_names
      # end
    end

    def logs_download(filename)
      xml = client.voxel_voxcast_ondemand_logs_download(:filename => filename)
      tempfile = Tempfile.new('log', "#{Rails.root}/tmp", :encoding => 'ASCII-8BIT')
      tempfile.write(Base64.decode64(xml['data']['content']))
      tempfile.flush
      tempfile
    end

  private

    def client
      @client ||= VoxelHAPI.new(:hapi_authkey => { :key => yml[:key], :secret => yml[:secret] })
    end

    def yml
      config_path = Rails.root.join('config', 'voxcast_cdn.yml')
      @default_storage ||= YAML::load_file(config_path)
      @default_storage.to_options
    rescue
      raise StandardError, "VoxcastCDN config file '#{config_path}' doesn't exist."
    end

    def parse_paths(paths)
      paths = paths.join('\n') if paths.is_a?(Array)
      paths
    end
  end
end