class Admin::DealsController < Admin::AdminController
  respond_to :html, :js

  # sort
  has_scope :by_id, :by_started_at, :by_ended_at

  def index
    @deals = apply_scopes(Deal.all)

    respond_with(@deals, per_page: 50)
  end

end
