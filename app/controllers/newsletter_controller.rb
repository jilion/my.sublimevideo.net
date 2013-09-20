class NewsletterController < ApplicationController

  # GET /newsletter/subscribe
  def subscribe
    NewsletterSubscriptionManager.delay(queue: 'my').subscribe(current_user.id)

    respond_to do |format|
      format.html { redirect_to sites_path, notice: t('flash.newsletter.subscribe') }
    end
  end

end
