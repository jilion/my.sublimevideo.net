class PlansController < ApplicationController
  before_filter :redirect_suspended_user
  before_filter :find_sites_or_redirect_to_new_site, only: [:edit, :update]
  before_filter :find_site_by_token!
  before_filter :set_current_plan, :set_custom_plan, only: [:edit, :update]

  # GET /sites/:site_id/plan/edit
  def edit
    respond_with(@site)
  end

  # PUT /sites/:site_id/plan
  def update
    # setting user_attributes will set user.attributes only only before validation (so, on the save below)
    @site.assign_attributes(params[:site].merge(remote_ip: request.try(:remote_ip)))

    respond_with(@site) do |format|
      if @site.save # will update site (& create invoice and charge it if skip_trial is true) # will create invoice and charge...
        notice_and_alert = notice_and_alert_from_transaction(@site.last_transaction)
        format.html { redirect_to :sites, notice_and_alert }
      else
        flash[:notice] = flash[:alert] = ""
        format.html { render :edit }
      end
    end
  end

  # Clear site.next_cycle_plan_id
  # DELETE /sites/:site_id/plan
  def destroy
    @site.update_attribute(:next_cycle_plan_id, nil)
    respond_with(@site, location: :sites)
  end

private

  def find_site_by_token!
    @site = current_user.sites.not_archived.find_by_token!(params[:site_id])
  end

end
