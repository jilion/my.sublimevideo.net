require 'fast_spec_helper'
require 'active_support/core_ext'
require File.expand_path('lib/video_tag_sources_analyzer')

describe VideoTagSourcesAnalyzer do
  context "with normal video sources" do
    let(:video_tag) { mock('VideoTag', sources_id: nil, sources_origin: nil, used_sources: {
      '57fb2708' => { url: 'http://standard.com/video.mp4' }
    }) }
    subject { described_class.new(video_tag) }

    its(:origin) { should eq 'other' }
    its(:id) { should be_nil }
  end

  context "with Vimeo video sources" do
    let(:video_tag) { mock('VideoTag', sources_id: nil, sources_origin: nil, used_sources: {
      '687d6ff' => { url: "http://player.vimeo.com/external/49154845.sd.mp4?s=f10c9e0acaf7cb38e9a5539c6fbcb4ac" }
    }) }
    subject { described_class.new(video_tag) }

    its(:origin) { should eq 'vimeo' }
    its(:id) { should eq '49154845' }
  end

  context "with YouTube video" do
    let(:video_tag) { mock('VideoTag', sources_id: 'youtube_id', sources_origin: 'youtube') }
    subject { described_class.new(video_tag) }

    its(:origin) { should eq 'youtube' }
    its(:id) { should eq 'youtube_id' }
  end
end
