class UserMailer < Mailer
  default template_path: "mailers/#{self.mailer_name}"

  %w[welcome account_suspended account_unsuspended account_archived].each do |method_name|
    define_method(method_name) do |user_id|
      _setup_from_user_id(user_id)
      mail to: @user.email, subject: _subject(method_name)
    end
  end

  private

  def _setup_from_user_id(user_id)
    @user = User.find(user_id)
  end

end
