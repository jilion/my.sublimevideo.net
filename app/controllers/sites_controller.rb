class SitesController < ApplicationController
  respond_to :html
  respond_to :js, :only => [:index, :code]

  before_filter :redirect_suspended_user
  before_filter :find_by_token, :only => [:code, :edit, :update, :destroy, :usage]

  has_scope :by_hostname
  has_scope :by_date

  # GET /sites
  def index
    @sites = current_user.sites.not_archived.includes(:plan)
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
  # Handle upfront charging + credit card infos storage here?
  def create
    # @site = current_user.sites.create(params[:site])
    @site = current_user.sites.build(params[:site])
    
    if @site.paid_plan? # charge NOW
      # 1/ Create invoice
      invoice = Invoice.build(site: @site)
      invoice.save!
      
      # 2/ Charge it
      transaction = Transaction.charge_by_invoice_ids([invoice.id])
      if transaction.failed?
        @site.errors.add(:base, transaction.error) # Acceptance test needed
      else
        
      end
      
      # store credit card infos (if present, the check is in the model)
      current_user.keep_some_credit_card_info
    end
      
    respond_with(@site, :location => :sites)
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

  # GET /sites/:id/usage
  def usage
    respond_with(@site) do |format|
      format.js
      format.html { redirect_to :sites }
    end
  end

private

  def find_by_token
    @site = current_user.sites.find_by_token(params[:id])
  end

end
