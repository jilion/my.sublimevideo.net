require 'fast_spec_helper'
require 'active_support/core_ext'
require 'support/private_api_helpers'

require 'video_stat'

describe VideoStat do
  let(:site_token) { 'site_token' }
  let(:video_uid) { 'my-video-1' }
  let(:video_tag) { double(site_token: site_token, uid: video_uid) }

  describe ".last_hours_stats" do
    before do
      stub_api_for(described_class) do |stub|
        stub.get("/private_api/sites/#{site_token}/videos/#{video_uid}/video_stats") { |env|
          [200, {}, { stats: [
            'st' => { 'w' => 1, 'e' => 1 }, 'co' => { 'w' => { 'us' => 12, 'fr' => 42 }, 'e' => { 'us' => 13, 'fr' => 43 } }
          ] }.to_json]
        }
      end
    end

    it "returns stats array" do
      described_class.last_hours_stats(video_tag, 24)[0].attributes.should eq({ 'st' => { 'w' => 1, 'e' => 1 }, 'co' => { 'w' => { 'us' => 12, 'fr' => 42 }, 'e' => { 'us' => 13, 'fr' => 43 } } })
    end
  end
end

