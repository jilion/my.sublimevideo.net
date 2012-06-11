require_dependency 'newsletter_manager'

class NewsletterController < ApplicationController

  # GET /newsletter/subscribe
  def subscribe
    NewsletterManager.subscribe(current_user)

    respond_to do |format|
      format.html { redirect_to sites_path, notice: I18n.t('flash.newsletter.subscribe') }
    end
  end

end
