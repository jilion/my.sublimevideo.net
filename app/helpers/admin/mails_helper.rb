module Admin::MailsHelper

  def mail_templates_for_select(selected_template)
    items = MailTemplate.not_archived.order(created_at: :desc).reduce([]) do |a, e|
      a << ["##{e.id} - #{e.title}", e.id]
    end

    options_for_select(items, selected_template.try(:id))
  end

  def mails_criteria
    grouped_criteria = {
     'Preview' => [],
     'User Type' => [],
     'Status' => []
    }

    grouped_criteria['Preview'] << ["Dev Team (#{display_integer(Administration::EmailSender::DEV_TEAM_EMAILS.size)})", 'dev']
    grouped_criteria['User Type'] << ["Paying (#{display_integer(User.paying.count)})", 'paying']
    grouped_criteria['User Type'] << ["Free (#{display_integer(User.free.count)})", 'free']
    grouped_criteria['Status'] << ["Active (#{display_integer(User.active.count)})", 'active']
    grouped_criteria['Status'] << ["Suspended (#{display_integer(User.suspended.count)})", 'suspended']
    grouped_criteria['Status'] << ["Not Archived (#{display_integer(User.not_archived.count)})", 'not_archived']

    grouped_options_for_select(grouped_criteria, 'dev')
  end

end
