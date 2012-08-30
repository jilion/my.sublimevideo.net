module AccountCancellationManager

  def self.archive_user_and_save_feedback(user, feedback)
    feedback.user_id = user.id

    ActiveRecord::Base.transaction do
      feedback.save!
      user.archive!
    end
  rescue StateMachine::InvalidTransition, ActiveRecord::RecordInvalid => ex
    false
  end

end
