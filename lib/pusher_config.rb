class PusherConfig < Settingslogic
  source "#{Rails.root}/config/pusher.yml"
  namespace Rails.env

  def self.key
    url.match(/^http:\/\/(\w*):.*$/)[1]
  end

end
