module Admin::MailsHelper

  def mails_criteria
    grouped_criteria = {
     'Preview' => [],
     'User Type' => [],
     'Status' => []
    }

    grouped_criteria['Preview'] <<  ["Dev Team (#{display_integer(MailLetter::DEV_TEAM_EMAILS.size)})", "dev"]
    grouped_criteria['User Type'] << ["Paying (#{display_integer(User.paying.size)})", "paying"]
    grouped_criteria['User Type'] << ["Free (#{display_integer(User.free.size)})", "free"]
    grouped_criteria['User Type'] << ["With page visits in the last 30 days (#{display_integer(User.with_page_loads_in_the_last_30_days.size)})", "with_page_loads_in_the_last_30_days"]
    grouped_criteria['User Type'] << ["With sites with the 'Your logo' add-on out of beta after Feb 20th WITHOUT CREDIT CARD (#{display_integer(User.without_cc.in_beta_trial_ended_after('logo-custom', Time.utc(2013, 2, 20)).size)})", "without_cc.in_beta_trial_ended_after('logo-custom', Time.utc(2013, 2, 20))"]
    grouped_criteria['User Type'] << ["With sites with the 'Your logo' add-on out of beta after Feb 20th WITH CREDIT CARD (#{display_integer(User.with_cc.in_beta_trial_ended_after('logo-custom', Time.utc(2013, 2, 20)).size)})", "with_cc.in_beta_trial_ended_after('logo-custom', Time.utc(2013, 2, 20))"]
    grouped_criteria['Status'] << ["Active (#{display_integer(User.active.size)})", "active"]
    grouped_criteria['Status'] << ["Suspended (#{display_integer(User.suspended.size)})", "suspended"]
    grouped_criteria['Status'] << ["Not Archived (#{display_integer(User.not_archived.size)})", "not_archived"]

    grouped_options_for_select(grouped_criteria, 'dev')
  end

end
