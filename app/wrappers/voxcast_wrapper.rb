require 'voxel_hapi'
require 'active_support/core_ext' # voxel_hapi should require this itself...
require 'rescue_me'
require 'tempfile'

module VoxcastWrapper

  def self.purge(path)
    if File.extname(path) == ''
      purge_dir(path)
    else
      purge_path(path)
    end
    Librato.increment 'cdn.purge', source: 'voxcast'
  end

  def self.purge_path(path)
    rescue_and_retry(2, Timeout::Error) do
      client.voxel_voxcast_ondemand_content_purge_file(device_id: ENV['VOXCAST_DEVICE_ID'], paths: path)
    end
  end

  def self.purge_dir(dir)
    rescue_and_retry(2, Timeout::Error) do
      client.voxel_voxcast_ondemand_content_purge_directory(device_id: ENV['VOXCAST_DEVICE_ID'], paths: dir)
    end
  end

  def self.logs_list(hostname)
    rescue_and_retry(2) do
      logs = client.voxel_voxcast_ondemand_logs_list(device_id: ENV['VOXCAST_DEVICE_ID'], hostname: ENV['VOXCAST_HOSTNAME'])
      logs['log_files']['sites']['hostname']['log_file']
    end
  end

  def self.download_log(filename)
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

  def self.client
    @@_client ||= VoxelHAPI.new(hapi_authkey: { key: ENV['VOXCAST_KEY'], secret: ENV['VOXCAST_SECRET'] })
  end

end
