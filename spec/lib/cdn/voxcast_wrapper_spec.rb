require 'fast_spec_helper'
require 'voxel_hapi'
require 'rescue_me'
require File.expand_path('spec/config/vcr')
require File.expand_path('lib/cdn/voxcast_wrapper')

describe CDN::VoxcastWrapper do

  describe "purge" do
    it "calls purge_path if a file path is given" do
      described_class.should_receive(:purge_path).with("/filepath.js")
      described_class.purge("/filepath.js")
    end

    it "calls purge_dir if a directory path is given" do
      described_class.should_receive(:purge_dir).with("/dir/path")
      described_class.purge("/dir/path")
    end
  end

  describe ".logs_list" do
    use_vcr_cassette "voxcast/logs_list"
    let(:logs_list) { described_class.logs_list(CDN::VoxcastWrapper.non_ssl_hostname) }


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

      specify { CDN::VoxcastWrapper.download_log("cdn.sublimevideo.net.log.1309836000-1309836060.gz").class.should eq Tempfile }
    end
  end

  describe ".ssl_hostname" do
    specify { CDN::VoxcastWrapper.ssl_hostname.should eq "4076.voxcdn.com" }
  end

  describe ".non_ssl_hostname" do
    specify { CDN::VoxcastWrapper.non_ssl_hostname.should eq "cdn.sublimevideo.net" }
  end

end
