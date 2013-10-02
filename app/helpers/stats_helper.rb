module StatsHelper

  def pusher_channel
    name = [@site.token, @video_tag.try(:uid)].compact.join('.')
    "private-#{name}"
  end

end
