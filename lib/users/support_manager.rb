module Users
  class SupportManager < Struct.new(:user)

    def level
      user.sites.not_archived.any? { |site| site.addon_plan_is_active?(AddonPlan.get('support', 'vip')) } ? 'vip_email' : 'email'
    end

  end
end
