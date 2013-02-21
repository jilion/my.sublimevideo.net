require 'fast_spec_helper'

require 'video_tag_old_data_updater_bridge'

describe VideoTagOldDataUpdaterBridge do
  let(:site_token) { 'site_token' }
  let(:uid) { 'uid' }
  let(:updater) { VideoTagOldDataUpdaterBridge.new(site_token, uid, old_data) }

  context "with uid & title from attribute" do
    let(:old_data) { {
      'uo' => 'a', 'n' => 'My Video', 'no' => 'a',
      'p' => 'http://posters.sublimevideo.net/video123.png',
    } }

    it "delays to VideoTagUpdaterWorker with translated data" do
      VideoTagUpdaterWorker.should_receive(:perform_async).with(site_token, uid, {
        uo: 'a',
        t: 'My Video',
        p: 'http://posters.sublimevideo.net/video123.png'
      })
      updater.update
    end
  end

  context "with uid from attribute & title from source" do
    let(:old_data) { {
      'uo' => 'a', 'n' => 'My Video', 'no' => 't',
      'p' => 'http://posters.sublimevideo.net/video123.png',
    } }

    it "delays to VideoTagUpdaterWorker with translated data (without title)" do
      VideoTagUpdaterWorker.should_receive(:perform_async).with(site_token, uid, {
        uo: 'a',
        p: 'http://posters.sublimevideo.net/video123.png'
      })
      updater.update
    end
  end

  context "with uid from source" do
    let(:old_data) { { 'uo' => 's' } }

    it "doesn't delays to VideoTagUpdaterWorker" do
      VideoTagUpdaterWorker.should_not_receive(:perform_async)
      updater.update
    end
  end
end
