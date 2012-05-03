require 'fast_spec_helper'
require_relative '../../../lib/video_tag_updater'
# require 'active_support/core_ext'
require 'bson'

describe VideoTagUpdater do

  VideoTag = Class.new unless defined?(VideoTag)
  PusherWrapper = Class.new unless defined?(PusherWrapper)

  before do
    VideoTag.stub(:find_by_st_and_u)
    VideoTag.stub(:create)
    PusherWrapper.stub(:trigger)
  end
  let(:meta_data) { { meta: 'data' } }
  let(:video_tags_meta_data) { {
    ['site_token_1', 'video_uid_1'] => meta_data,
    ['site_token_2', 'video_uid_2'] => meta_data
  } }

  context "with new video tags in trackers" do
    it "create a two new video tags" do
      VideoTag.should_receive(:create).with(st: 'site_token_1', u: 'video_uid_1', meta: 'data')
      VideoTag.should_receive(:create).with(st: 'site_token_2', u: 'video_uid_2', meta: 'data')
      described_class.update_video_tags(video_tags_meta_data)
    end

    it "trigger Pusher for each new video tags created" do
      PusherWrapper.should_receive(:trigger).with('private-site_token_1', 'video_tag', u: 'video_uid_1', meta_data: { meta: 'data' })
      PusherWrapper.should_receive(:trigger).with('private-site_token_2', 'video_tag', u: 'video_uid_2', meta_data: { meta: 'data' })
      described_class.update_video_tags(video_tags_meta_data)
    end
  end

  context "with an existing video tags in tracker" do
    let(:video_tag) { stub }
    before do
      VideoTag.should_receive(:find_by_st_and_u).with('site_token_1', 'video_uid_1') { video_tag }
    end

    it "update meta data" do
      video_tag.should_receive(:update_meta_data_and_always_updated_at).with(meta_data)
      described_class.update_video_tags(video_tags_meta_data)
    end

    it "trigger Pusher if changed" do
      video_tag.stub(:update_meta_data_and_always_updated_at) { true }
      PusherWrapper.should_receive(:trigger).with('private-site_token_1', 'video_tag', u: 'video_uid_1', meta_data: { meta: 'data' })
      described_class.update_video_tags(video_tags_meta_data)
    end

    it "doesn't trigger Pusher if not changed" do
      video_tag.stub(:update_meta_data_and_always_updated_at) { false }
      PusherWrapper.should_not_receive(:trigger).with('private-site_token_1', 'video_tag', u: 'video_uid_1', meta_data: { meta: 'data' })
      described_class.update_video_tags(video_tags_meta_data)
    end

  end
  #
  # describe "#push_new_meta_data" do
  #
  #   it "push after save" do
  #     video_tag = VideoTag.new(st: 'site1234', u: 'video123', n: 'Video 123')
  #     PusherWrapper.should_receive(:trigger).once.with("private-site1234", 'video_tag', u: 'video123', meta_data: video_tag.meta_data)
  #     video_tag.save
  #   end
  #
  # end
  #
  # describe ".create_or_update_from_trackers!" do
  #
  #   context "with a new video (load)" do
  #     before do
  #       described_class.stub(:video_tags_from_trackers).and_return({
  #         ['site1234', 'video123'] => { 'z' => '300x400' }
  #       })
  #     end
  #
  #     specify { expect { described_class.create_or_update_from_trackers!(nil) }.to change(VideoTag, :count).by(1) }
  #     specify { expect { 2.times { described_class.create_or_update_from_trackers!(nil) } }.to change(VideoTag, :count).by(1) }
  #
  #     describe "new video_tag" do
  #       subject do
  #         described_class.create_or_update_from_trackers!(nil)
  #         VideoTag.first
  #       end
  #
  #       its(:z) { should eql('300x400') }
  #     end
  #   end
  #
  #   context "with a new video (view)" do
  #     before do
  #       described_class.stub(:video_tags_from_trackers).and_return({
  #         ['site1234', 'video123'] => { 'uo' => 'a', 'n' => 'My Video', 'no' => 's',
  #           'p'  => 'http://posters.sublimevideo.net/video123.png',
  #           'cs' => ['source12', 'source34'],
  #           's'  => {
  #             'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
  #             'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' }
  #           }
  #         }
  #       })
  #     end
  #
  #     specify { expect { described_class.create_or_update_from_trackers!(nil) }.to change(VideoTag, :count).by(1) }
  #     specify { expect { 2.times { described_class.create_or_update_from_trackers!(nil) } }.to change(VideoTag, :count).by(1) }
  #
  #     describe "new video_tag" do
  #       subject do
  #         described_class.create_or_update_from_trackers!(nil)
  #         VideoTag.first
  #       end
  #
  #       its(:st) { should eql('site1234') }
  #       its(:u)  { should eql('video123') }
  #       its(:uo) { should eql('a') }
  #       its(:n)  { should eql('My Video') }
  #       its(:no) { should eql('s') }
  #       its(:p)  { should eql('http://posters.sublimevideo.net/video123.png') }
  #       its(:cs) { should eql(['source12', 'source34']) }
  #       its(:s)  { should eql({
  #         'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
  #         'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' }
  #       }) }
  #     end
  #
  #     describe "existing video_tag (different)" do
  #       before do
  #         Timecop.travel 1.hour.ago do
  #           @video_tag = video_tag
  #         end
  #       end
  #       subject do
  #         described_class.create_or_update_from_trackers!(nil)
  #         VideoTag.first
  #       end
  #
  #       its(:st) { should eql('site1234') }
  #       its(:u)  { should eql('video123') }
  #       its(:uo) { should eql('a') }
  #       its(:n)  { should eql('My Video') }
  #       its(:no) { should eql('s') }
  #       its(:p)  { should eql('http://posters.sublimevideo.net/video123.png') }
  #       its(:cs) { should eql(['source12', 'source34']) }
  #       its(:s)  { should eql({
  #         'source11' => { 'u' => 'http://videos.sublimevideo.net/source11.mp4', 'q' => 'base', 'f' => 'mp4', 'r' => '460x340' },
  #         'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
  #         'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' }
  #       }) }
  #       its(:created_at) { should eql(@video_tag.created_at) }
  #       its(:updated_at) { should_not == @video_tag.updated_at }
  #     end
  #
  #     describe "existing video_tag (no change)" do
  #       before do
  #         Timecop.travel 1.hour.ago do
  #           described_class.create_or_update_from_trackers!(nil)
  #           @video_tag = VideoTag.first
  #         end
  #       end
  #       subject do
  #         described_class.create_or_update_from_trackers!(nil)
  #         VideoTag.first
  #       end
  #
  #       its(:st) { should eql('site1234') }
  #       its(:u)  { should eql('video123') }
  #       its(:uo) { should eql('a') }
  #       its(:n)  { should eql('My Video') }
  #       its(:no) { should eql('s') }
  #       its(:p)  { should eql('http://posters.sublimevideo.net/video123.png') }
  #       its(:cs) { should eql(['source12', 'source34']) }
  #       its(:s)  { should eql({
  #         'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
  #         'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' }
  #       }) }
  #       its(:created_at) { should eql(@video_tag.created_at) }
  #       its(:updated_at) { should eql(@video_tag.updated_at) }
  #     end
  #   end
  #
  # end


end
