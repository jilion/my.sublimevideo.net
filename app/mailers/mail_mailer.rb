class MailMailer < SublimeVideoMailer
  
  def send_mail_with_template(user, template)
    mail(:to => user.email, :subject => template.subject, :body => Liquid::Template.parse(template.subject).render("user" => user))
  end
  
end