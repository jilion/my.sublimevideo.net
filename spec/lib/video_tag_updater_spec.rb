require 'fast_spec_helper'
require File.expand_path('lib/video_tag_updater')

unless defined?(ActiveRecord)
  Site = Class.new
  VideoTag = Class.new
  PusherWrapper = Class.new
end

describe VideoTagUpdater do
  let(:data) { {
    'uo' => 's', 'n' => 'My Video', 'no' => 'a',
    'p' => 'http://posters.sublimevideo.net/video123.png',
    'z' => '640x360',
    'd' => '10000',
    'cs' => ['source11'],
    's' => {
      'source11' => { 'u' => 'http://videos.sublimevideo.net/source11.mp4', 'q' => 'base', 'f' => 'mp4', 'r' => '460x340' },
    }
  } }
  let(:site) { mock(Site, id: 'site_id', token: 'site_token') }
  let(:video_tag) { mock(VideoTag, uid: 'uid', data: data, valid?: true, changed?: true, save: true) }

  describe ".update" do

    context "with existing site" do
      let(:relation) { stub }
      let(:delayed_job_mock) { mock(trigger: true) }
      before do
        Site.stub_chain(:where, :first) { site }
        VideoTag.stub_chain(:where, :first_or_initialize) { video_tag }
        video_tag.stub(:attributes=)
        PusherWrapper.stub(:delay) { delayed_job_mock }
      end

      it "updates video_tag attributes with data" do
        VideoTag.should_receive(:where).with(
          site_id: site.id,
          uid: video_tag.uid
        ) { relation }
        relation.should_receive(:first_or_initialize) { video_tag }
        video_tag.should_receive(:attributes=).with(
          uid_origin: 'source',
          name: 'My Video',
          name_origin: 'attribute',
          poster_url: 'http://posters.sublimevideo.net/video123.png',
          size:     '640x360',
          duration:   '10000',
          current_sources: ['source11'],
          sources: {
            'source11' => {
              url: 'http://videos.sublimevideo.net/source11.mp4',
              quality: 'base',
              family: 'mp4',
              resolution: '460x340'
            }
          }
        ) { video_tag }
        video_tag.should_receive(:save)
        VideoTagUpdater.update(site.id, video_tag.uid, data)
      end

      it "trigs Pusher if video_tags data are valid and changed" do
        delayed_job_mock.should_receive(:trigger).with(
          "private-#{site.token}",
          'video_tag',
          video_tag.data
        )
        VideoTagUpdater.update(site.id, video_tag.uid, data)
      end

      it "doesnt't trig Pusher if video_tags data are invalid" do
        video_tag.stub(:valid?) { false }
        PusherWrapper.should_not_receive(:trigger)
        VideoTagUpdater.update(site.id, video_tag.uid, data)
      end

      it "doesnt't trig Pusher if video_tags data doesn't change" do
        video_tag.stub(:changed?) { false }
        PusherWrapper.should_not_receive(:trigger)
        VideoTagUpdater.update(site.id, video_tag.uid, data)
      end
    end

    context "with unexisting site" do
      before { Site.stub_chain(:where, :first) { nil } }

      it "does nothing" do
        VideoTag.should_not_receive(:where)
        VideoTagUpdater.update(site.id, video_tag.uid, data)
      end
    end
  end
end
