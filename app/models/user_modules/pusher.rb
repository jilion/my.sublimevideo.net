module UserModules::Pusher
  extend ActiveSupport::Concern

  module ClassMethods

    def accessible_channel?(channel_name, user = nil)
      if matches = channel_name.match(/private-([a-z0-9]{4,8})$/)
        site_token = matches[1]
        site_token == 'demo' || (user && user.sites.where(token: site_token).exists?)
      end
    end

  end

end
