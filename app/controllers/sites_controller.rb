class SitesController < ApplicationController
  respond_to :html
  respond_to :js, :only => [:index, :code]

  before_filter :redirect_suspended_user
  before_filter :find_sites_or_redirect_to_new_site, :only => :index
  before_filter :find_by_token!, :only => [:code, :edit, :update, :destroy, :usage]

  has_scope :by_hostname
  has_scope :by_date

  # GET /sites
  def index
    @sites = current_user.sites.not_archived.includes(:plan, :next_cycle_plan, :invoices)
    @sites = apply_scopes(@sites).by_date
    respond_with(@sites, :per_page => 10)
  end

  # GET /sites/new
  def new
    @site = current_user.sites.build((params[:site] || {}).reverse_merge(:dev_hostnames => Site::DEFAULT_DEV_DOMAINS))
    respond_with(@site)
  end

  # GET /sites/:id/edit
  def edit
    respond_with(@site)
  end

  # POST /sites
  def create
    @site = current_user.sites.build(params[:site])

    # setting user_attributes will set user.attributes only before validation (so, on the save below)
    # in order to set the credit card in the charging_options site's attribute, user.attributes have to be set before calling user.credit_card
    @site.user.assign_attributes(params[:site][:user_attributes]) if @site.in_or_will_be_in_paid_plan? && !@site.will_be_in_free_plan?
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
          flash[:notice] = ""
          flash[:alert] = ""
          format.html { render :text => d3d_html_inject(@site.transaction.error) }
        else
          format.html { redirect_to :sites, notice_and_alert_from_transaction(@site.transaction) }
        end
      else
        flash[:notice] = ""
        flash[:alert] = ""
        format.html { render :new }
      end
    end
  end

  # PUT /sites/:id
  def update
    @site.update_attributes(params[:site])
    respond_with(@site, :location => :sites)
  end

  # DELETE /sites/:id
  def destroy
    @site.user_attributes = params[:site] && params[:site][:user_attributes]

    respond_with(@site) do |format|
      if @site.archive
        format.html { redirect_to :sites }
      else
        format.html { render :edit }
      end
    end
  end

  # GET /sites/:id/state
  def state
    @site = current_user.sites.not_archived.find(params[:id])
    respond_with(@site) do |format|
      format.js
      format.html { redirect_to :sites }
    end
  end

  # GET /sites/:id/code
  def code
    respond_with(@site) do |format|
      format.js
      format.html { redirect_to :sites }
    end
  end

  # # GET /sites/:id/usage
  # def usage
  #   respond_with(@site) do |format|
  #     format.js
  #     format.html { redirect_to :sites }
  #   end
  # end

  private

  def find_sites_or_redirect_to_new_site
    @sites = current_user.sites.not_archived.includes(:plan, :next_cycle_plan)
    @sites = apply_scopes(@sites).by_date
    redirect_to [:new, :site] if @sites.empty?
  end

  def find_by_token!
    @site = current_user.sites.not_archived.find_by_token!(params[:id])
  end

end
