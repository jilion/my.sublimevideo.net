module Admin::MailsHelper

  def mails_criteria
    grouped_criteria = {
     'Preview' => [],
     'User Type' => [],
     'Status' => []
    }

    grouped_criteria['Preview'] <<  ["Dev Team (#{display_integer(MailLetter::DEV_TEAM_EMAILS.size)})", "dev"]
    grouped_criteria['User Type'] << ["Paying (#{display_integer(User.paying.count)})", "paying"]
    grouped_criteria['User Type'] << ["Free (#{display_integer(User.free.count)})", "free"]
    grouped_criteria['User Type'] << ["With page visits in the last 30 days (#{display_integer(User.with_page_loads_in_the_last_30_days.count)})", "with_page_loads_in_the_last_30_days"]
    grouped_criteria['User Type'] << ["With sites with the 'Your logo' add-on out of beta after Feb 20th WITHOUT CREDIT CARD (#{display_integer(User.without_cc.in_beta_trial_ended_after('logo-custom', Time.utc(2013, 2, 20)).count)})", "without_cc.in_beta_trial_ended_after('logo-custom', Time.utc(2013, 2, 20))"]
    grouped_criteria['User Type'] << ["With sites with the 'Your logo' add-on out of beta after Feb 20th WITH CREDIT CARD (#{display_integer(User.with_cc.in_beta_trial_ended_after('logo-custom', Time.utc(2013, 2, 20)).count)})", "with_cc.in_beta_trial_ended_after('logo-custom', Time.utc(2013, 2, 20))"]
    grouped_criteria['User Type'] << ["With Real-Time Stats add-on or invalid video tag data-uid  (#{display_integer(User.with_stats_realtime_addon_or_invalid_video_tag_data_uid.count)})", "with_stats_realtime_addon_or_invalid_video_tag_data_uid"]
    grouped_criteria['Status'] << ["Active (#{display_integer(User.active.count)})", "active"]
    grouped_criteria['Status'] << ["Suspended (#{display_integer(User.suspended.count)})", "suspended"]
    grouped_criteria['Status'] << ["Not Archived (#{display_integer(User.not_archived.count)})", "not_archived"]

    grouped_options_for_select(grouped_criteria, 'dev')
  end

end
