require 'fast_spec_helper'
require File.expand_path('lib/new_video_tag_updater')

unless defined?(ActiveRecord)
  Site = Class.new
  VideoTag = Class.new
end

describe NewVideoTagUpdater do
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
  let(:site) { mock(Site, id: 'site_id') }
  let(:video_tag) { mock(VideoTag, uid: 'uid') }

  describe ".update" do

    context "with existing site" do
      before { Site.stub_chain(:where, :first) { site } }

      it "updates video_tag attributes with data" do
        VideoTag.should_receive(:first_or_initialize).with(
          site_id: site.id,
          uid: video_tag.uid
        ) { video_tag }
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
        NewVideoTagUpdater.update(site.id, video_tag.uid, data)
      end
    end

    context "with unexisting site" do
      before { Site.stub_chain(:where, :first) { nil } }

      it "does nothing" do
        VideoTag.should_not_receive(:first_or_initialize)
        NewVideoTagUpdater.update(site.id, video_tag.uid, data)
      end
    end
  end
end
