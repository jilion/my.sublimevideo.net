class Admin::DealActivationsController < Admin::AdminController
  respond_to :html, :js

  def index
    @deal_activations = apply_scopes(DealActivation.includes(:deal, :user).order{ activated_at.desc })

    respond_with(@deal_activations, per_page: 50)
  end

end
