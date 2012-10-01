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
    grouped_criteria['Status'] << ["Active (#{display_integer(User.active.size)})", "active"]
    grouped_criteria['Status'] << ["Suspended (#{display_integer(User.suspended.size)})", "suspended"]
    grouped_criteria['Status'] << ["Not Archived (#{display_integer(User.not_archived.size)})", "not_archived"]

    grouped_options_for_select(grouped_criteria, 'dev')
  end

end
