class VideoStatsMergerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'my-low'

  def perform(site_token, uid, old_uid)
    VideoStatsMerger.new(site_token, uid, old_uid).merge!
    Librato.increment 'video_stats.merge'
  end
end
