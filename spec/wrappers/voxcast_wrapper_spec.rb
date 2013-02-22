require 'fast_spec_helper'
require 'configurator'
require 'voxel_hapi'
require 'rescue_me'
require 'config/vcr'

require 'wrappers/voxcast_wrapper'

describe VoxcastWrapper do

  describe "purge" do
    before { Librato.stub(:increment) }

    it "calls purge_path if a file path is given" do
      described_class.should_receive(:purge_path).with("/filepath.js")
      described_class.purge("/filepath.js")
    end

    it "calls purge_dir if a directory path is given" do
      described_class.should_receive(:purge_dir).with("/dir/path")
      described_class.purge("/dir/path")
    end

    it "increments metrics" do
      described_class.stub(:purge_path)
      Librato.should_receive(:increment).with('cdn.purge', source: 'voxcast')
      described_class.purge("/filepath.js")
    end
  end

  describe ".logs_list" do
    use_vcr_cassette "voxcast/logs_list"
    let(:logs_list) { described_class.logs_list(VoxcastWrapper.hostname) }


    it "returns all logs" do
      logs_list.should have(21597).logs
    end

    it "returns logs name" do
      logs_list.first["content"].should eq('cdn.sublimevideo.net.log.1349001120-1349001180.gz')
    end
  end

  describe ".download_log" do
    context "when log available" do
      use_vcr_cassette "voxcast/download_log_available"

      specify { VoxcastWrapper.download_log("cdn.sublimevideo.net.log.1309836000-1309836060.gz").class.should eq Tempfile }
    end
  end

  describe ".hostname" do
    specify { VoxcastWrapper.hostname.should eq "4076.voxcdn.com" }
  end

end