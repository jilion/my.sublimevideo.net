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
        stub.get("/private_api/sites/#{site_token}/videos/#{video_uid}/last_video_stats") { |env|
          [200, {}, { stats: [{'lo' => 2, 'st' => 1}] }.to_json]
        }
      end
    end

    it "returns stats array" do
      stat = described_class.last_stats(video_tag)[0]
      expect(stat.loads).to eq 2
      expect(stat.starts).to eq 1
    end
  end
end

