class UserSupportManager
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def level
    if _vip_email_support_accessible?
      'vip_email'
    elsif user.trial_or_billable?
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
    @vip_email_support_accessible ||= user.sites.not_archived.any? { |site| site.subscribed_to?(AddonPlan.get('support', 'vip')) }
  end

end
