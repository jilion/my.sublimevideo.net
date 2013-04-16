class UserSupportManager
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def email_support?
    level =~ /email/
  end

  def vip_email_support?
    level == 'vip_email'
  end

  def level
    if _vip_email_support_accessible?
      'vip_email'
    elsif user.trial_or_billable? || user.sponsored?
      'email'
    end
  end

  def max_reply_business_days
    if _vip_email_support_accessible?
      1
    elsif user.trial_or_billable?
      5
    end
  end

  def _vip_email_support_accessible?
    @vip_email_support_accessible ||= begin
      vip_support_addon_plan = AddonPlan.get('support', 'vip')
      user.sites.not_archived.any? do |site|
        site.subscribed_to?(vip_support_addon_plan) || site.sponsored_to?(vip_support_addon_plan)
      end
    end
  end

end
