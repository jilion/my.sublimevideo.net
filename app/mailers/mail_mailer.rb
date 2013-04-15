class MailMailer < Mailer

  def send_mail_with_template(user_id, template_id)
    @user     = User.find(user_id)
    template  = MailTemplate.find(template_id)
    @no_reply = true

    mail(to: @user.email, subject: Liquid::Template.parse(template.subject).render('user' => @user)) do |format|
      format.html { render text: Liquid::Template.parse(template.body).render('user' => @user), layout: 'mailer' }
    end
  end

end
