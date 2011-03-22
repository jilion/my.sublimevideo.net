class SitesController < ApplicationController
  respond_to :html
  respond_to :js, :only => [:index, :code]

  before_filter :redirect_suspended_user
  before_filter :find_by_token, :only => [:code, :edit, :update, :destroy, :usage]

  has_scope :by_hostname
  has_scope :by_date

  # GET /sites
  def index
    @sites = current_user.sites.not_archived.includes(:plan, :next_cycle_plan)
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
    @site.d3d_options = {
      user: @site.user,
      accept_url: sites_url,
      decline_url: sites_url,
      exception_url: sites_url,
      ip: request.try(:remote_ip),
      action: "create"
    }

    respond_with(@site) do |format|
      if @site.save # will create invoice and charge...
        transaction = @site.last_invoice.transaction

        if transaction.waiting_d3d?
          format.html { render :text => transaction.d3d_html }

        elsif transaction.failed?
          format.html { redirect_to [:edit, @site, :plan], :alert => t("transaction.errors.#{transaction.error_code}") }

        elsif transaction.succeed? || transaction.error_key == "unknown"
          format.html { redirect_to :sites, :notice => t(transaction.succeed? ? "flash.sites.create.notice" : "transaction.errors.#{transaction.error_key}") }

        end
      else
        format.html { render :edit }
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
    @site = current_user.sites.find(params[:id])
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

  def find_by_token
    @site = current_user.sites.find_by_token(params[:id])
  end

end
