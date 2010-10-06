class MailMailer < SublimeVideoMailer
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  
  def send_mail_with_template(user, template)
    mail(:to => "#{user.full_name} <#{user.email}>",
      :subject => Liquid::Template.parse(template.subject).render("user" => user)) do |format|
      format.text { render :text => auto_link(simple_format(Liquid::Template.parse(template.body).render("user" => user))) }
    end
  end
  
end