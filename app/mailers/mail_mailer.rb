class MailMailer < Mailer

  def send_mail_with_template(user, template)
    mail(
      to: to(user),
      subject: Liquid::Template.parse(template.subject).render("user" => user)
    ) do |format|
      format.html { render text: Liquid::Template.parse(template.body).render("user" => user) }
    end
  end

end
