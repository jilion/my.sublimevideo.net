class Admin::DealsController < Admin::AdminController
  respond_to :html, :js

  # sort
  has_scope :by_id
  has_scope :by_started_at
  has_scope :by_ended_at

  def index
    @deals = apply_scopes(Deal.scoped)

    respond_with(@deals, per_page: 50)
  end

end
