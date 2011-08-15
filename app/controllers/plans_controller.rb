class PlansController < ApplicationController
  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!

  # GET /sites/:site_id/plan/edit
  def edit
    respond_with(@site)
  end

  # PUT /sites/:site_id/plan
  def update
    # setting user_attributes will set user.attributes only only before validation (so, on the save below)
    # in order to set the credit card in the charging_options site's attribute, user.attributes have to be set before calling user.credit_card
    @site.assign_attributes(params[:site])
    @site.user.assign_attributes(params[:site][:user_attributes])
    @site.charging_options = {
      credit_card: @site.user.credit_card,
      accept_url: sites_url,
      decline_url: sites_url,
      exception_url: sites_url,
      ip: request.try(:remote_ip)
    }

    respond_with(@site) do |format|
      if @site.save # will create invoice and charge...
        if @site.transaction.try(:waiting_d3d?)
          format.html { render :text => d3d_html_inject(@site.transaction.error) }
        else
          format.html { redirect_to :sites, notice_and_alert_from_transaction(@site.transaction) }
        end
      else
        flash[:notice] = ""
        flash[:alert] = ""
        format.html { render :edit }
      end
    end
  end

  # Clear site.next_cycle_plan_id
  # DELETE /sites/:site_id/plan
  def destroy
    @site.update_attribute(:next_cycle_plan_id, nil)
    respond_with(@site, :location => :sites)
  end

private

  def find_site_by_token!
    @site = current_user.sites.find_by_token!(params[:site_id])
  end

end
