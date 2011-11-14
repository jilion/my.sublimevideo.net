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
      if @site.archived? || @site.skip_pwd { @site.archive }
        @site.refund
        format.html { redirect_to [:refunds], :notice => t('site.refund.refunded', hostname: @site.hostname) }
      else
        format.html { redirect_to [:refunds], :alert => t('site.refund.refund_unsuccessful', hostname: @site.hostname) }
      end
    end
  end

end
