require_dependency 'service/site'

class PlansController < ApplicationController
  before_filter :redirect_suspended_user, :find_sites_or_redirect_to_new_site, :find_site_by_token!

  # GET /sites/:site_id/plan/opt_out
  def opt_out
  end

  # POST /sites/:site_id/plan/confirm_opt_out
  def confirm_opt_out
    Service::Site.new(@site).opt_out_from_grandfather_plan
    redirect_to thanks_site_addons_path, notice: 'Add-ons successfully updated.'
  end

end
