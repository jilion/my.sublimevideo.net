require 'fast_spec_helper'
require 'action_view'

require 'helpers/video_tags_helper'

describe VideoTagsHelper do
  let(:video_tag) { double('VideoTag',
    uid:  'uid-token',
    name: 'My Video',
    poster_url: 'http://media.sublimevideo.net/vpa/ms_800.jpg',
    sources: [
      { url: 'http://media.sublimevideo.net/vpa/ms_360p.mp4',  quality: 'base', family: 'mp4' },
      { url: 'http://media.sublimevideo.net/vpa/ms_720p.mp4',  quality: 'hd',   family: 'mp4' },
      { url: 'http://media.sublimevideo.net/vpa/ms_360p.webm', quality: 'base', family: 'webm' },
      { url: 'http://media.sublimevideo.net/vpa/ms_720p.webm', quality: 'hd',   family: 'webm' }
    ]
  )}

  module Helper
    def self.config; end
    def self.controller; end

    extend VideoTagsHelper
    extend ActionView::Context
    extend ActionView::Helpers::CaptureHelper
    extend ActionView::Helpers::UrlHelper
    extend ActionView::Helpers::AssetTagHelper
    extend ActionView::Helpers::TagHelper
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

  describe "#proxied_image_tag" do
    it "returns image tag via images.weserv.nl" do
      Helper.proxied_image_tag('http://sublimevideo.net/image.jpg').should eq(
        "<img alt=\"Image\" src=\"https://images.weserv.nl?url=sublimevideo.net/image.jpg\" />")
    end

    it "returns image tag via images.weserv.nl with size options" do
      Helper.proxied_image_tag('http://sublimevideo.net/image.jpg', size: '60x40').should eq(
        "<img alt=\"Image\" height=\"40\" src=\"https://images.weserv.nl?url=sublimevideo.net/image.jpg&amp;w=60&amp;h=40\" width=\"60\" />")
    end

    it "returns image tag via images.weserv.nl with scheme less url" do
      Helper.proxied_image_tag('sublimevideo.net/image.jpg', size: '60x40').should eq(
        "<img alt=\"Image\" height=\"40\" src=\"https://images.weserv.nl?url=sublimevideo.net/image.jpg&amp;w=60&amp;h=40\" width=\"60\" />")
    end
  end

end
