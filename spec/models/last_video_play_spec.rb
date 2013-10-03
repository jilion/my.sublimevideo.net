require 'fast_spec_helper'
require 'active_support/core_ext'
require 'support/private_api_helpers'

require 'last_video_play'

describe LastVideoPlay do
  let(:time) { 1.hour.ago }
  let(:site_token) { 'site_token' }
  let(:video_uid) { 'my-video-1' }
  let(:video_tag) { double(site_token: site_token, uid: video_uid) }

  before do
    stub_api_for(described_class) do |stub|
      stub.get("/private_api/sites/#{site_token}/videos/#{video_uid}/last_plays") { |env|
        [200, {}, { plays: [
          {'t' => time.to_s, 'du' => 'http://sublimevideo.net/', 'ru' => 'http://google.com/' },
          {'t' => time.to_s, 'du' => 'http://sublimevideo.net/<script type="text/javascript">alert("foo!");</script>', 'ru' => 'http://google.com/<script type="text/javascript">alert("foo!");</script>' },
          {'t' => time.to_s, 'du' => nil, 'ru' => nil }
        ] }.to_json]
      }
    end
  end

  describe '.last_plays' do
    it 'returns stats array' do
      stat = described_class.last_plays(video_tag)[0]
      expect(stat.du).to eq 'http://sublimevideo.net/'
      expect(stat.ru).to eq 'http://google.com/'
    end
  end

  describe '#time' do
    it { expect(described_class.last_plays(video_tag)[0].time.to_i).to eq time.to_i }
  end

  describe '#document_url' do
    it { expect(described_class.last_plays(video_tag)[0].document_url).to eq 'http://sublimevideo.net/' }
    it { expect(described_class.last_plays(video_tag)[1].document_url).to eq 'http://sublimevideo.net/&lt;script type=&quot;text/javascript&quot;&gt;alert(&quot;foo!&quot;);&lt;/script&gt;' }
    it { expect(described_class.last_plays(video_tag)[2].document_url).to eq '' }
  end

  describe '#referrer_url' do
    it { expect(described_class.last_plays(video_tag)[0].referrer_url).to eq 'http://google.com/' }
    it { expect(described_class.last_plays(video_tag)[1].referrer_url).to eq 'http://google.com/&lt;script type=&quot;text/javascript&quot;&gt;alert(&quot;foo!&quot;);&lt;/script&gt;' }
    it { expect(described_class.last_plays(video_tag)[2].referrer_url).to eq '' }
  end

  describe '#referrer_url?' do
    it { expect(described_class.last_plays(video_tag)[0].referrer_url?).to be_true }
    it { expect(described_class.last_plays(video_tag)[1].referrer_url?).to be_true }
    it { expect(described_class.last_plays(video_tag)[2].referrer_url?).to be_false }
  end

end

