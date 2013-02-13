class PusherChannel
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def self.accessible?(user = nil)
    if matches = name.try(:match, /private-([a-z0-9]{4,8})$/)
      site_token = matches[1]
      site_token == SiteToken[:www] || (user && user.sites.where(token: site_token).exists?)
    end
  end

end