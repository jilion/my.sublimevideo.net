class DealsController < ApplicationController
  respond_to :html

  prepend_before_filter :set_cookie
  before_filter :find_deal_by_token!

  def show
    deal_activation = current_user.deal_activations.build(deal_id: @deal.id)
    if deal_activation.save
      cookies.delete :d, domain: :all
    end

    respond_to do |format|
      format.html { redirect_to :sites }
    end
  end

private

  def set_cookie
    if params[:id]
      cookies[:d] = {
        value: params[:id],
        expires: 2.hours.from_now,
        domain: :all
      }
    end
  end

  def find_deal_by_token!
    @deal = Deal.find_by_token!(params[:id])
  end

end