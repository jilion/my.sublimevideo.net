class PusherConfig < Settingslogic
  source "#{Rails.root}/config/pusher.yml"
  namespace Rails.env
end