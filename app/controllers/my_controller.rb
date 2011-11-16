class MyController < ApplicationController
  include CustomDevisePaths
  include MyRedirectionFilters

  responders Responders::FlashResponder

  before_filter :authenticate_user!
  before_filter :set_cookie_for_menu

private

  def user_for_paper_trail
    params[:user][:email].downcase! if params[:user] && params[:user][:email]
    current_user rescue nil
  end

  def info_for_paper_trail
    { :admin_id => current_admin_id, :ip => request.remote_ip }
  end

  def current_admin_id
    current_admin.try(:id) rescue nil
  end

  def find_sites_or_redirect_to_new_site
    @sites = current_user.sites.not_archived.includes(:plan, :next_cycle_plan, :invoices)
    @sites = apply_scopes(@sites).by_date

    redirect_to [:new, :site] if @sites.empty?
  end

  def set_cookie_for_menu
    unless cookies[:l]
      cookies[:l] = {
        value: true,
        expires: 1.hour.from_now,
        domain: :all
      }
    end
  end

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

end
