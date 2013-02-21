require 'sidekiq'

class VideoTagUpdaterWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'videos'

  def perform(site_token, uid, data)
    # method handled in sisv
  end
end
