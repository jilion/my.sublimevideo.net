class UserSupportManager
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def level
    if user.sites.not_archived.any? { |site| site.addon_plan_is_active?(AddonPlan.get('support', 'vip')) }
      'vip_email'
    else
      'email'
    end
  end

end
