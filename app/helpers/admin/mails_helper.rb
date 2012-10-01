module Admin::MailsHelper

  def mails_criteria
    grouped_criteria = {
     'Preview' => [],
     'User Type' => [],
     'Status' => []
    }

    grouped_criteria['Preview'] <<  ["Dev Team (#{display_integer(MailLetter::DEV_TEAM_EMAILS.size)})", "dev"]
    # FIXME
    # grouped_criteria['User Type'] << ["Paying (#{display_integer(User.paying.size)})", "paying"]
    # grouped_criteria['User Type'] << ["Free (#{display_integer(User.free.size)})", "free"]
    # grouped_criteria['User Type'] << ["In trial (#{display_integer(User.includes(:sites).merge(Site.in_trial).where{ sites.trial_started_at == nil }.uniq.size)})", "trial"]
    # grouped_criteria['User Type'] << ["In old trial (#{display_integer(User.includes(:sites).merge(Site.in_trial).where{ sites.trial_started_at != nil }.uniq.size)})", "old_trial"]
    grouped_criteria['Status'] << ["Active (#{display_integer(User.active.size)})", "active"]
    grouped_criteria['Status'] << ["Suspended (#{display_integer(User.suspended.size)})", "suspended"]
    grouped_criteria['Status'] << ["Not Archived (#{display_integer(User.not_archived.size)})", "not_archived"]

    grouped_options_for_select(grouped_criteria, 'dev')
  end

end
