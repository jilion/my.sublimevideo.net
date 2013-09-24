require 'voxel_hapi'
require 'active_support/core_ext' # voxel_hapi should require this itself...
require 'rescue_me'
require 'tempfile'

module VoxcastWrapper

  def self.purge(path)
    _purge_with_retry(path)
    Librato.increment 'cdn.purge', source: 'voxcast'
  end

  def self.logs_list(hostname)
    rescue_and_retry(2) do
      logs = _client.voxel_voxcast_ondemand_logs_list(device_id: ENV['VOXCAST_DEVICE_ID'], hostname: ENV['VOXCAST_HOSTNAME'])
      logs['log_files']['sites']['hostname']['log_file']
    end
  end

  def self.download_log(filename)
    rescue_and_retry(2) do
      xml = _client.voxel_voxcast_ondemand_logs_download(filename: filename)
      tempfile = Tempfile.new('log', Rails.root.join('tmp'), encoding: 'ASCII-8BIT')
      tempfile.write(Base64.decode64(xml['data']['content']))
      tempfile.flush
      tempfile
    end
  rescue VoxelHAPI::Backend => ex
    ex.to_s =~ /log file not found/ ? false : raise(ex)
  end

  def self._purge_with_retry(path)
    kind = File.extname(path) == '' ? 'directory' : 'file'
    rescue_and_retry(2, Timeout::Error) do
      _client.send(:"voxel_voxcast_ondemand_content_purge_#{kind}", device_id: ENV['VOXCAST_DEVICE_ID'], paths: path)
    end
  end

  def self._client
    @@_client ||= VoxelHAPI.new(hapi_authkey: { key: ENV['VOXCAST_KEY'], secret: ENV['VOXCAST_SECRET'] })
  end

end
