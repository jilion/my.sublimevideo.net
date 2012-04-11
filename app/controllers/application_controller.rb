class ApplicationController < ActionController::Base
  include MyRedirectionFilters

  helper :all

  respond_to :html
  responders Responders::HttpCacheResponder, Responders::PaginatedResponder, Responders::FlashResponder

  before_filter :authenticate_user!
  before_filter :set_logged_in_cookie

  protect_from_forgery

  private

  def user_for_paper_trail
    params[:user][:email].downcase! if params[:user] && params[:user][:email]
    current_user rescue nil
  end

  def info_for_paper_trail
    { admin_id: current_admin_id, ip: current_ip }
  end

  def current_admin_id
    current_admin.try(:id) rescue nil
  end

  def current_ip
    request.remote_ip rescue nil
  end

  def find_sites_or_redirect_to_new_site
    @sites = current_user.sites.not_archived.includes(:plan, :next_cycle_plan, :invoices)
    @sites = apply_scopes(@sites).by_date

    redirect_to [:new, :site] if @sites.empty?
  end

  def set_logged_in_cookie
    if user_signed_in?
      cookies[:l] = {
        value: '1',
        expires: 2.weeks.from_now,
        domain: :all,
        secure: false
      }
    else
      cookies.delete :l, domain: :all
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

module DeviseInvitable::Controllers::Helpers
  protected
  def authenticate_inviter!
    authenticate_admin!
  end
end

require "action_controller/metal"

module Devise
  class FailureApp < ActionController::Metal

    def redirect_url
      opts  = {}
      route = :"new_#{scope}_session_url"
      opts[:format] = request_format unless skip_format?
      opts[:subdomain] = case scope
                         when :user
                           'my'
                         when :admin
                           'admin'
                         else
                           nil
                         end

      if respond_to?(route)
        send(route, opts)
      else
        root_path(opts)
      end
    end

  end
end
