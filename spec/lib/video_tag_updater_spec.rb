require 'fast_spec_helper'
require File.expand_path('lib/video_tag_updater')

unless defined?(ActiveRecord)
  Site = Class.new
  VideoTag = Class.new
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
  let(:video_tag) { mock(VideoTag,
    id: 'video_tag_id',
    uid: 'video_tag_uid',
    data: data,
    site: site,
    :name= => true, :name_origin= => true,
    :sources_id= => true, :sources_origin= => true,
    :attributes= => true
  ) }
  let(:sources_analyzer) { mock(origin: "sources_origin", id: "sources_id") }
  let(:name_fetcher) { mock(name: "new name", origin: 'name_origin') }

  describe ".update" do
    context "with existing site" do
      let(:relation) { stub }

      before do
        Site.stub_chain(:where, :first) { site }
        VideoTag.stub_chain(:where, :first_or_initialize) { video_tag }
        video_tag.stub(:valid?) { true }
        video_tag.stub(:changed?) { true }
        video_tag.stub(:save) { true }
        PusherWrapper.stub(:trigger)
        VideoTagSourcesAnalyzer.stub(:new) { sources_analyzer }
        VideoTagNameFetcher.stub(:new) { name_fetcher }
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

      it "clear name and name origin if not present in data" do
        data_without_name = data.except('n', 'no')
        video_tag.should_receive(:attributes=).with(
          uid_origin: 'source',
          name: nil,
          name_origin: nil,
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

        VideoTagUpdater.update(site.id, video_tag.uid, data_without_name)
      end

      context "video_tags data are valid and changed" do
        it "trigs PusherWrapper" do
          PusherWrapper.should_receive(:trigger).with(
            "private-#{site.token}",
            'video_tag',
            video_tag.data
          )
          VideoTagUpdater.update(site.id, video_tag.uid, data)
        end

        it "sets sources_id & sources_origin from VideoTagSourcesAnalyzer" do
          VideoTagSourcesAnalyzer.should_receive(:new).with(video_tag) { sources_analyzer }
          video_tag.should_receive(:sources_origin=).with(sources_analyzer.origin)
          video_tag.should_receive(:sources_id=).with(sources_analyzer.id)
          VideoTagUpdater.update(site.id, video_tag.uid, data)
        end

        it "sets name from VideoTagNameFetcher" do
          VideoTagNameFetcher.should_receive(:new).with(video_tag) { name_fetcher }
          video_tag.should_receive(:name=).with(name_fetcher.name)
          video_tag.should_receive(:name_origin=).with(name_fetcher.origin)
          VideoTagUpdater.update(site.id, video_tag.uid, data)
        end
      end

      context "video_tags data are invalid" do
        before { video_tag.stub(:valid?) { false } }

        it "doesnt't trig Pusher" do
          PusherWrapper.should_not_receive(:trigger)
          VideoTagUpdater.update(site.id, video_tag.uid, data)
        end

        it "doesnt't set sources_id & sources_origin from VideoTagSourcesAnalyzer" do
          VideoTagSourcesAnalyzer.should_not_receive(:new)
          VideoTagUpdater.update(site.id, video_tag.uid, data)
        end

        it "doesnt't set name from VideoTagNameFetcher" do
          VideoTagNameFetcher.should_not_receive(:new)
          VideoTagUpdater.update(site.id, video_tag.uid, data)
        end
      end

      context "video_tags data doesn't change" do
        before { video_tag.stub(:changed?) { false } }

        it "doesnt't trig Pusher" do
          PusherWrapper.should_not_receive(:trigger)
          VideoTagUpdater.update(site.id, video_tag.uid, data)
        end

        it "doesnt't set sources_id & sources_origin from VideoTagSourcesAnalyzer" do
          VideoTagSourcesAnalyzer.should_not_receive(:new)
          VideoTagUpdater.update(site.id, video_tag.uid, data)
        end

        it "doesnt't set name from VideoTagNameFetcher" do
          VideoTagNameFetcher.should_not_receive(:new)
          VideoTagUpdater.update(site.id, video_tag.uid, data)
        end
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

  describe ".update_name" do
    before do
      VideoTag.stub(:find).with(video_tag.id) { video_tag }
      VideoTagSourcesAnalyzer.stub(:new) { sources_analyzer }
      VideoTagNameFetcher.stub(:new) { name_fetcher }
      video_tag.stub(:save) { true }
    end

    it "sets sources_id & sources_origin from VideoTagSourcesAnalyzer" do
      VideoTagSourcesAnalyzer.should_receive(:new).with(video_tag) { sources_analyzer }
      video_tag.should_receive(:sources_origin=).with(sources_analyzer.origin)
      video_tag.should_receive(:sources_id=).with(sources_analyzer.id)
      VideoTagUpdater.update_name(video_tag.id)
    end

    it "sets name from VideoTagNameFetcher" do
      VideoTagNameFetcher.should_receive(:new).with(video_tag) { name_fetcher }
      video_tag.should_receive(:name=).with(name_fetcher.name)
      video_tag.should_receive(:name_origin=).with(name_fetcher.origin)
      VideoTagUpdater.update_name(video_tag.id)
    end
  end

end
