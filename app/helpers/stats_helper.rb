module StatsHelper

  def auth_token
    token = [@site.token, @video_tag.try(:uid)].join(':')
    token.encrypt(:symmetric)
  end

end
