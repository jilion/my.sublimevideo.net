require 'spec_helper'

describe VideoTagMigrator do
  let(:migrator) { VideoTagMigrator.new(video_tag) }
  let(:video_tag) { create(:video_tag) }

  context "with uid from attribute" do
    context "standard data" do
      it "delays VideoTagUpdaterWorker with clean data" do
        VideoTagUpdaterWorker.should_receive(:perform_async).with(video_tag.site.token, video_tag.uid, {
          uo: 'a',
          t: video_tag.name,
          p: video_tag.poster_url,
          d: video_tag.duration,
          z: video_tag.size,
          s: [
            { u: 'http://media.sublimevideo.net/vpa/ms_360p.mp4', q: 'base', f: 'mp4', r: '640x360' },
            { u: 'http://media.sublimevideo.net/vpa/ms_720p.mp4', q: 'hd', f: 'mp4', r: '1280x720' },
            { u: 'http://media.sublimevideo.net/vpa/ms_360p.webm', q: 'base', f: 'webm', r: '640x360' },
            { u: 'http://media.sublimevideo.net/vpa/ms_720p.webm', q: 'hd', f: 'webm', r: '1280x720' },
          ],
          created_at: video_tag.created_at,
          updated_at: video_tag.updated_at
        })
        migrator.migrate
      end
    end

    context "with name from source" do
      before { video_tag.update_attribute(:name_origin, 'source') }

      it "delays VideoTagUpdaterWorker with clean data" do
        VideoTagUpdaterWorker.should_receive(:perform_async).with(video_tag.site.token, video_tag.uid, {
          uo: 'a',
          p: video_tag.poster_url,
          d: video_tag.duration,
          z: video_tag.size,
          s: [
            { u: 'http://media.sublimevideo.net/vpa/ms_360p.mp4', q: 'base', f: 'mp4', r: '640x360' },
            { u: 'http://media.sublimevideo.net/vpa/ms_720p.mp4', q: 'hd', f: 'mp4', r: '1280x720' },
            { u: 'http://media.sublimevideo.net/vpa/ms_360p.webm', q: 'base', f: 'webm', r: '640x360' },
            { u: 'http://media.sublimevideo.net/vpa/ms_720p.webm', q: 'hd', f: 'webm', r: '1280x720' },
          ],
          created_at: video_tag.created_at,
          updated_at: video_tag.updated_at
        })
        migrator.migrate
      end
    end

    context "with youtube video" do
      before { video_tag.update_attributes(sources_origin: 'youtube', sources_id: 'youtube_id') }

      it "delays VideoTagUpdaterWorker with clean data" do
        VideoTagUpdaterWorker.should_receive(:perform_async).with(video_tag.site.token, video_tag.uid, {
          uo: 'a',
          t: video_tag.name,
          p: video_tag.poster_url,
          d: video_tag.duration,
          z: video_tag.size,
          i: 'youtube_id',
          io: 'y',
          created_at: video_tag.created_at,
          updated_at: video_tag.updated_at
        })
        migrator.migrate
      end
    end
  end

  context "with uid from source" do
    before { video_tag.update_attribute(:uid_origin, 'source') }

    context "with more than 1 day of stats" do
      before {
        Stat::Video::Day.create(st: video_tag.site.token, u: video_tag.uid)
        Stat::Video::Day.create(st: video_tag.site.token, u: video_tag.uid)
      }

      it "delays VideoTagUpdaterWorker with clean data" do
        VideoTagUpdaterWorker.should_receive(:perform_async)
        migrator.migrate
      end

      it "keeps video stats" do
        migrator.migrate
        Stat::Video::Day.count.should eq 2
      end
    end

    context "with 1 day or less of stats" do
      before {
        Stat::Video::Day.create(st: video_tag.site.token, u: video_tag.uid, d: 1.month.ago)
      }

      it "deletes video_tag" do
        migrator.migrate
        VideoTag.where(id: video_tag.id).first.should be_nil
      end

      it "deletes video stats" do
        migrator.migrate
        Stat::Video::Day.count.should eq 0
      end
    end
  end

end
