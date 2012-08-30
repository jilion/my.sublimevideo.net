class Admin::FeedbacksController < Admin::AdminController
  respond_to :html, :js

  before_filter :set_default_scopes, only: [:index]

  # sort
  has_scope :by_date, :by_reason, :by_kind

  def index
    @feedbacks = apply_scopes(Feedback.scoped)

    respond_with(@feedbacks, per_page: 50)
  end

  private

  def set_default_scopes
    params[:by_date] = 'desc' unless params.keys.any? { |k| k =~ /^by_\w+$/ }
  end

end
