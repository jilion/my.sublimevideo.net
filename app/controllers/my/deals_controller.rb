class My::DealsController < MyController
  respond_to :html

  prepend_before_filter :set_cookie
  before_filter :find_deal_by_token!

  def show
    current_user.deal_activations.create(deal_id: @deal.id)
    cookies.delete :d, domain: :all

    respond_to do |format|
      format.html { redirect_to :sites }
    end
  end

private

  def set_cookie
    if params[:id]
      cookies[:d] = {
        value: params[:id],
        expires: 2.weeks.from_now,
        domain: :all,
        httponly: true
      }
    end
  end

  def find_deal_by_token!
    @deal = Deal.find_by_token!(params[:id])
  end

end
