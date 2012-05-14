class GoodbyeManager

  def self.archive_user_and_save_feedback(user, goodbye_feedback)
    goodbye_feedback.user_id = user.id

    if goodbye_feedback.valid? && user.valid?
      goodbye_feedback.save
      user.archive
    else
      false
    end
  end

end
