class ApplicationController < ActionController::Base
  include CustomDevisePaths
  include RedirectionFilters

  respond_to :html
  responders Responders::FlashResponder, Responders::PaginatedResponder, Responders::HttpCacheResponder

  layout 'application'

  before_filter :authenticate_user!

  protect_from_forgery

private

  def user_for_paper_trail
    params[:user][:email].downcase! if params[:user] && params[:user][:email]
    current_user rescue nil
  end

  def info_for_paper_trail
    { :admin_id => current_admin_id, :ip => request.remote_ip, :user_agent => request.user_agent }
  end

  def current_admin_id
    current_admin.try(:id) rescue nil
  end

  def zeno?
    (admin_signed_in? && current_admin.email == "zeno@jilion.com") || Rails.env.development?
  end
  helper_method :zeno?

  def mehdi?
    (admin_signed_in? && current_admin.email == "mehdi@jilion.com") || Rails.env.development?
  end
  helper_method :mehdi?

  def octave?
    (admin_signed_in? && current_admin.email == "octave@jilion.com") || Rails.env.development?
  end
  helper_method :octave?

  module DeviseInvitable::Controllers::Helpers
  protected
    def authenticate_inviter!
      authenticate_admin!
    end
  end

  def d3d_html_inject(text)
    "<!DOCTYPE html><html><head><title>3DS Redirection</title></head><body>#{text}</body></html>"
  end

  # =============================
  # = transaction flash message =
  # =============================

  def notice_and_alert_from_transaction(transaction)
    case transaction.try(:state)
    when "failed", "waiting"
      { notice: "", alert: t("transaction.errors.#{transaction.state}") }
    else
      { notice: nil, alert: nil }
    end
  end

  def notice_and_alert_from_user(user)
    user.i18n_notice_and_alert.present? ? { notice: "", alert: "" }.merge(user.i18n_notice_and_alert) : { notice: t('flash.credit_cards.update.notice'), alert: nil }
  end

end
