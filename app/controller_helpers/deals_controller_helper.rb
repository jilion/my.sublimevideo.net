module DealsControllerHelper

  def activate_deal_from_cookie
    if cookies[:d]
      if deal = Deal.find_by_token(cookies[:d])
        deal_activation = current_user.deal_activations.build(deal_id: deal.id)
        cookies.delete(:d, domain: :all) if deal_activation.save
      end
    end
  end

end
