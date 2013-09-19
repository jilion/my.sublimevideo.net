require 'fast_spec_helper'
require 'config/vcr'

require 'wrappers/voxcast_wrapper'

describe VoxcastWrapper do

  describe '.purge' do
    let(:voxel_hapi) { double('VoxelHAPI', voxel_voxcast_ondemand_content_purge_file: true) }
    before do
      described_class.stub(:_client) { voxel_hapi }
      Librato.stub(:increment)
    end

    it 'calls voxel_voxcast_ondemand_content_purge_file if a file path is given' do
      voxel_hapi.should_receive(:voxel_voxcast_ondemand_content_purge_file).with(device_id: ENV['VOXCAST_DEVICE_ID'], paths: '/filepath.js')
      described_class.purge('/filepath.js')
    end

    it 'calls voxel_voxcast_ondemand_content_purge_directory if a directory path is given' do
      voxel_hapi.should_receive(:voxel_voxcast_ondemand_content_purge_directory).with(device_id: ENV['VOXCAST_DEVICE_ID'], paths: '/dir/path')
      described_class.purge('/dir/path')
    end

    it 'increments metrics' do
      Librato.should_receive(:increment).with('cdn.purge', source: 'voxcast')
      described_class.purge('/filepath.js')
    end
  end

  describe '.logs_list' do
    use_vcr_cassette 'voxcast/logs_list'
    let(:logs_list) { described_class.logs_list(ENV['VOXCAST_HOSTNAME']) }


    it 'returns all logs' do
      logs_list.should have(21597).logs
    end

    it 'returns logs name' do
      logs_list.first['content'].should eq('cdn.sublimevideo.net.log.1349001120-1349001180.gz')
    end
  end

  describe '.download_log' do
    context 'when log available' do
      use_vcr_cassette 'voxcast/download_log_available'

      specify { described_class.download_log('cdn.sublimevideo.net.log.1309836000-1309836060.gz').class.should eq Tempfile }
    end
  end

  describe '.hostname' do
    specify { ENV['VOXCAST_HOSTNAME'].should eq '4076.voxcdn.com' }
  end

end
