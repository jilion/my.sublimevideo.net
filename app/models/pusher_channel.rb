class PusherChannel
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def accessible?(user = nil)
    if matches = name.try(:match, /private-([a-z0-9]{4,8})/)
      site_token = matches[1]
      site_token == SiteToken[:www] || (user && user.sites.where(token: site_token).exists?)
    end
  end

  def occupied!
    Sidekiq.redis { |con| con.sadd('pusher:channels', name) }
  end

  def vacated!
    Sidekiq.redis { |con| con.srem('pusher:channels', name) }
  end

  def occupied?
    Sidekiq.redis { |con| con.sismember('pusher:channels', name) }
  end

  def vacated?
    !occupied?
  end

  def public?
    !private?
  end

  def private?
    name =~ /^private-.*/
  end

  def to_s
    name
  end
end
