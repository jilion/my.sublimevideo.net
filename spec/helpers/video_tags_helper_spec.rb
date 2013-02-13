require 'fast_spec_helper'
require 'action_view'

require 'helpers/video_tags_helper'

describe VideoTagsHelper do
  let(:video_tag) { mock('VideoTag',
    uid:  'uid-token',
    name: 'My Video',
    poster_url: 'http://media.sublimevideo.net/vpa/ms_800.jpg',
    used_sources: {
      'base_mp4_crc32'  => { 'url' => 'http://media.sublimevideo.net/vpa/ms_360p.mp4',  'quality' => 'base', 'family' => 'mp4' },
      'hd_mp4_crc32'    => { 'url' => 'http://media.sublimevideo.net/vpa/ms_720p.mp4',  'quality' => 'hd',   'family' => 'mp4' },
      'base_webm_crc32' => { 'url' => 'http://media.sublimevideo.net/vpa/ms_360p.webm', 'quality' => 'base', 'family' => 'webm' },
      'hd_webm_crc32'   => { 'url' => 'http://media.sublimevideo.net/vpa/ms_720p.webm', 'quality' => 'hd',   'family' => 'webm' }
    }
  )}

  module Helper
    def self.config; end
    def self.controller; end

    extend VideoTagsHelper
    extend ActionView::Context
    extend ActionView::Helpers::CaptureHelper
    extend ActionView::Helpers::UrlHelper
    extend ActionView::Helpers::AssetTagHelper
  end

  describe "#duration_string" do
    it "renders one second when less than a seconds only properly" do
      Helper.duration_string(499).should eq "00:01"
    end
    it "renders seconds only properly" do
      Helper.duration_string(59*1000).should eq "00:59"
    end
    it "renders minutes only properly" do
      Helper.duration_string(59*60*1000).should eq "59:00"
    end
    it "renders hours only properly" do
      Helper.duration_string(60*60*1000).should eq "1:00:00"
    end
    it "renders a lot of hours only properly" do
      Helper.duration_string(25*60*60*1000).should eq "25:00:00"
    end
    it "renders complete duration properly" do
      Helper.duration_string(1*60*60*1000 + 34*60*1000 + 23*1000).should eq "1:34:23"
    end
    it "renders ?:??:?? if duration is nil" do
      Helper.duration_string(nil).should eq "?:??:??"
    end
  end

  describe "#playable_lightbox" do
    it "returns complete" do
      Helper.playable_lightbox(video_tag, size: '96x54').should eq(
        "<a href=\"//dehqkotcrv4fy.cloudfront.net/vcg/ms_360p.mp4\" class=\"sublime\"><img alt=\"Ms_800\" height=\"54\" src=\"http://media.sublimevideo.net/vpa/ms_800.jpg\" width=\"96\" /></a><video class=\"sublime lightbox\" data-name=\"My Video\" data-uid=\"uid-token\" height=\"360\" poster=\"http://media.sublimevideo.net/vpa/ms_800.jpg\" preload=\"none\" style=\"display:none\" width=\"640\"><source src=\"http://media.sublimevideo.net/vpa/ms_360p.mp4\" /><source data-quality=\"hd\" src=\"http://media.sublimevideo.net/vpa/ms_720p.mp4\" /><source src=\"http://media.sublimevideo.net/vpa/ms_360p.webm\" /><source data-quality=\"hd\" src=\"http://media.sublimevideo.net/vpa/ms_720p.webm\" /></video>"
      )
    end
  end
end
