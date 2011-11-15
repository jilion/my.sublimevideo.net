class My::PlansController < MyController
  before_filter :redirect_suspended_user
  before_filter :find_sites_or_redirect_to_new_site, only: [:edit, :update]
  before_filter :find_site_by_token!

  # GET /sites/:site_id/plan/edit
  def edit
    respond_with(@site)
  end

  # PUT /sites/:site_id/plan
  def update
    # setting user_attributes will set user.attributes only only before validation (so, on the save below)
    @site.assign_attributes(params[:site].merge(remote_ip: request.try(:remote_ip)))
    @site.user.assign_attributes(params[:site][:user_attributes])

    respond_with(@site) do |format|
      if @site.save # will create invoice and charge...
        if @site.last_transaction.try(:waiting_d3d?)
          format.html { render :text => d3d_html_inject(@site.last_transaction.error) }
        else
          format.html { redirect_to :sites, notice_and_alert_from_transaction(@site.last_transaction) }
        end
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
    respond_with(@site, :location => :sites)
  end

private

  def find_site_by_token!
    @site = current_user.sites.not_archived.find_by_token!(params[:site_id])
  end

end
