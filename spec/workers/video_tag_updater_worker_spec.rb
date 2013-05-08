require 'fast_spec_helper'
require 'config/sidekiq'

require 'video_tag_updater_worker'

describe VideoTagUpdaterWorker do

  it "performs async job" do
    expect {
      VideoTagUpdaterWorker.perform_async('site_token', 'new_uid', {})
    }.to change(VideoTagUpdaterWorker.jobs, :size).by(1)
  end

  it "delays job in low (mysv) queue" do
    VideoTagUpdaterWorker.get_sidekiq_options['queue'].should eq 'videos'
  end
end
