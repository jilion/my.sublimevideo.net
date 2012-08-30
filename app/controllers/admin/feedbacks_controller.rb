class Admin::FeedbacksController < Admin::AdminController
  respond_to :html, :js

  # sort
  has_scope :by_created_at, :by_reason, :by_kind

  def index
    @feedbacks = apply_scopes(Feedback.scoped)

    respond_with(@feedbacks, per_page: 50)
  end

end
