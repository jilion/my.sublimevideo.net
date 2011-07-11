require 'spec_helper'

describe VoxcastCDN do

  describe ".download_log" do
    context "when log not available" do
      use_vcr_cassette "voxcast/download_log_not_available"

      specify { VoxcastCDN.download_log("cdn.sublimevideo.net.log.9999999900-9999999960.gz").should be_false }
    end

    context "when log available" do
      use_vcr_cassette "voxcast/download_log_available"

      specify { VoxcastCDN.download_log("cdn.sublimevideo.net.log.1309836000-1309836060.gz").class.should eq Tempfile }
    end
  end

  describe ".ssl_hostname" do
    specify { VoxcastCDN.ssl_hostname.should eq "4076.voxcdn.com" }
  end
  describe ".non_ssl_hostname" do
    specify { VoxcastCDN.non_ssl_hostname.should eq "cdn.sublimevideo.net" }
  end

end
