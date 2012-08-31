module Admin::FeedbacksHelper

  def display_kind(feedback)
    feedback.kind ? t("feedback.kind.#{feedback.kind}") : "Cancellation"
  end

end
