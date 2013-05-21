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

  def enterprise_email_support?
    level == 'enterprise_email'
  end

  def level
    if _vip_email_support_accessible?
      'vip_email'
    elsif _enterprise_email_support_accessible?
      'enterprise_email'
    elsif user.trial_or_billable? || user.sponsored?
      'email'
    end
  end

  def guaranteed_response_time
    case level
    when 'email'
      3600 * 24 * 5
    when 'vip_email'
      3600 * 24
    when 'enterprise_email'
      3600
    end
  end

  private

  def _vip_email_support_accessible?
    @_vip_email_support_accessible ||= _subscribed_or_sponsored_to_support('vip')
  end

  def _enterprise_email_support_accessible?
    @_enterprise_email_support_accessible ||= _subscribed_or_sponsored_to_support('enterprise')
  end

  def _subscribed_or_sponsored_to_support(plan)
    addon_plan = _get_addon_plan(plan)
    user.sites.not_archived.any? do |site|
      site.subscribed_to?(addon_plan) || site.sponsored_to?(addon_plan)
    end
  end

  def _get_addon_plan(plan)
    require 'addon_plan'
    AddonPlan.get('support', plan)
  end

end
