module UserModules::Pusher
  extend ActiveSupport::Concern

  module InstanceMethods

    def accessible_channel?(channel_name)
      if matches = channel_name.match(/[presence|private]-([a-z0-9]{8})$/)
        site_token = matches[1]
        self.sites.where(token: site_token).exists?
      end
    end

  end

end
