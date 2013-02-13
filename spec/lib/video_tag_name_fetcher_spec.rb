require 'fast_spec_helper'
require 'active_support/core_ext'

require File.expand_path('lib/video_tag_name_fetcher')
require 'wrappers/vimeo_wrapper'
require 'wrappers/youtube_wrapper'

describe VideoTagNameFetcher do

  context "with normal video sources" do
    let(:video_tag) { mock('VideoTag', name: 'Video Name', name_origin: 'source', sources_origin: 'other') }
    subject { described_class.new(video_tag) }

    its(:name) { should eq 'Video Name' }
    its(:origin) { should eq 'source' }
  end

  context "with video sources with overwritten name" do
    let(:video_tag) { mock('VideoTag', name: 'Overwritten Video Name', name_origin: 'attribute', sources_origin: 'vimeo') }
    subject { described_class.new(video_tag) }

    its(:name) { should eq 'Overwritten Video Name' }
    its(:origin) { should eq 'attribute' }
  end

  context "with Vimeo video sources" do
    let(:video_tag) { mock('VideoTag', name: 'video_file_name', name_origin: 'source', sources_origin: 'vimeo', sources_id: 'vimeo_video_id') }
    subject { described_class.new(video_tag) }
    before { VimeoWrapper.should_receive(:new).with(video_tag.sources_id) { stub(video_title: 'Vimeo Video Name') } }

    its(:name) { should eq 'Vimeo Video Name' }
    its(:origin) { should eq 'vimeo' }
  end

  context "with Vimeo video sources with private video" do
    let(:video_tag) { mock('VideoTag', name: 'video_file_name', name_origin: 'source', sources_origin: 'vimeo', sources_id: 'vimeo_video_id') }
    subject { described_class.new(video_tag) }
    before { VimeoWrapper.should_receive(:new).with(video_tag.sources_id) { stub(video_title: nil) } }

    its(:name) { should eq 'video_file_name' }
    its(:origin) { should eq 'source' }
  end

  context "with YouTube video" do
    let(:video_tag) { mock('VideoTag', name: nil, name_origin: nil, sources_origin: 'youtube', sources_id: 'youtube_video_id') }
    subject { described_class.new(video_tag) }
    before { YouTubeWrapper.should_receive(:new).with(video_tag.sources_id) { stub(video_title: 'YouTube Video Name') } }

    its(:name) { should eq 'YouTube Video Name' }
    its(:origin) { should eq 'youtube' }
  end

  context "with YouTube video wrong id" do
    let(:video_tag) { mock('VideoTag', name: nil, name_origin: nil, sources_origin: 'youtube', sources_id: 'youtube_video_id') }
    subject { described_class.new(video_tag) }
    before { YouTubeWrapper.should_receive(:new).with(video_tag.sources_id) { stub(video_title: nil) } }

    its(:name) { should be_nil }
    its(:origin) { should be_nil }
  end

end
