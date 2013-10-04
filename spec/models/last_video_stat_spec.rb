require 'fast_spec_helper'
require 'active_support/core_ext'
require 'support/private_api_helpers'

require 'last_video_stat'

describe LastVideoStat do
  let(:site_token) { 'site_token' }
  let(:video_uid) { 'my-video-1' }
  let(:video_tag) { double(site_token: site_token, uid: video_uid) }

  describe ".last_stats" do
    before do
      stub_api_for(described_class) do |stub|
        stub.get("/private_api/last_video_stats?site_token=#{site_token}&video_uid=#{video_uid}") { |env|
          [200, {}, [{'lo' => 2, 'st' => 1}].to_json]
        }
      end
    end

    it "returns stats array" do
      stat = described_class.last_stats(video_tag)[0]
      expect(stat.lo).to eq 2
      expect(stat.st).to eq 1
    end
  end
end

