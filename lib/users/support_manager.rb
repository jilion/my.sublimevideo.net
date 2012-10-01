module Users
  class SupportManager < Struct.new(:user)

    def level
      vip_support_addon = Addons::Addon.get('support', 'vip')
      user.sites.not_archived.any? { |site| site.addon_is_active?(vip_support_addon) } ? 'vip_email' : 'email'
    end

  end
end
