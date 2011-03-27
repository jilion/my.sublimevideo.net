class RefundsController < ApplicationController
  respond_to :html

  def index
    @sites = current_user.sites.refundable
    respond_with(@sites)
  end

  # POST /refund/:id
  def create
    @site = current_user.sites.refundable.find(params[:site_id])
    
    respond_to do |format|
      if @site.archived? || @site.without_password_validation { @site.archive }
        Site.transaction do
          Transaction.delay.refund_by_site_id(@site.id)
          @site.touch(:refunded_at)
        end
        format.html { redirect_to refunds_url, :notice => t('site.refund.refunded', hostname: @site.hostname) }
      else
        format.html { redirect_to refunds_url, :alert => t('site.refund.refund_unsuccessful', hostname: @site.hostname) }
      end
    end
  end

end
