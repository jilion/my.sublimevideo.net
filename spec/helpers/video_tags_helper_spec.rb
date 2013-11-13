require 'fast_spec_helper'
require 'action_view'
require 'active_support/core_ext'

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

  describe "#last_starts_days" do
    before { Helper.stub(:params) { params } }

    context "no filter" do
      let(:params) { { } }

      it "returns 30" do
        expect(Helper.last_starts_days).to eq 30
      end
    end

    context "filter is last_30_days_active" do
      let(:params) { { filter: 'last_30_days_active' } }

      it "returns 30" do
        expect(Helper.last_starts_days).to eq 30
      end
    end

    context "filter is last_90_days_active" do
      let(:params) { { filter: 'last_90_days_active' } }

      it "returns 90" do
        expect(Helper.last_starts_days).to eq 90
      end
    end

    context "filter is last_365_days_active" do
      let(:params) { { filter: 'last_365_days_active' } }

      it "returns 365" do
        expect(Helper.last_starts_days).to eq 365
      end
    end
  end

  describe "last_grouped_starts" do
    let(:starts) { 365.times.map { 1 } }

    context "with 30 days" do
      let(:days) { 30 }

      it "returns last 30" do
        expect(Helper.last_grouped_starts(starts, days)).to eq 30.times.map { 1 }
      end
    end

    context "with 90 days" do
      let(:days) { 90 }

      it "returns last 90 stats grouped by 2" do
        expect(Helper.last_grouped_starts(starts, days)).to eq 45.times.map { 2 }
      end
    end

    context "with 365 days" do
      let(:days) { 365 }

      it "returns last 365 starts grouped by 5" do
        expect(Helper.last_grouped_starts(starts, days)).to eq 73.times.map { 5 }
      end
    end
  end
end
