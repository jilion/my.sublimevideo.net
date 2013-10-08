class DealsController < ApplicationController
  prepend_before_filter :_set_cookie
  before_filter :_set_deal

  def show
    deal_activation = current_user.deal_activations.build(deal_id: @deal.id)
    cookies.delete(:d, domain: :all) if deal_activation.save

    redirect_to :sites
  end

private

  def _set_cookie
    if params[:id]
      cookies[:d] = {
        value: params[:id],
        expires: 2.hours.from_now,
        domain: :all,
        secure: Rails.env.production?
      }
    end
  end

  def _set_deal
    @deal = Deal.where(token: params[:id]).first!
  end

end
