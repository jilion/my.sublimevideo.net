class GoodbyeManager

  def self.archive_user_and_save_feedback(user, password, goodbye_feedback)
    user.current_password    = password
    goodbye_feedback.user_id = user.id

    ActiveRecord::Base.transaction do
      goodbye_feedback.save!
      user.archive!
    end
  rescue StateMachine::InvalidTransition, ActiveRecord::RecordInvalid => ex
    false
  end

end
