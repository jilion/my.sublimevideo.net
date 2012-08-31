require_dependency 'demo_site_helper'
require_dependency 'my_redirection_filters'
require_dependency 'early_access'
require_dependency 'responders/paginated_responder'
require_dependency 'pjax'

class ApplicationController < ActionController::Base
  include MyRedirectionFilters
  include SublimeVideoLayoutHelper
  include EarlyAccess
  include DemoSiteHelper
  include Pjax

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

  def set_current_plan
    @current_plan = (@site.pending_plan || @site.next_cycle_plan || @site.plan) if @site
  end

  def set_custom_plan
    @custom_plan = if params[:custom_plan]
      Plan.custom_plans.find_by_token(params[:custom_plan])
    elsif @current_plan && @current_plan.custom_plan?
      @current_plan
    end
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
