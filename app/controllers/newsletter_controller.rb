require_dependency 'service/newsletter'

class NewsletterController < ApplicationController

  # GET /newsletter/subscribe
  def subscribe
    Service::Newsletter.delay.subscribe(current_user.id)

    respond_to do |format|
      format.html { redirect_to sites_path, notice: t('flash.newsletter.subscribe') }
    end
  end

end
