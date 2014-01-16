class AssistantController < ApplicationController
  before_filter :_set_sites
  before_filter :_set_site, :_update_current_assistant_step_and_redirect, except: [:new_site]
  before_filter :_set_default_kit!, only: [:player, :publish_video]

  # GET /assistant/new-site
  # POST /assistant/new-site
  def new_site
    case request.request_method_symbol
    when :get
      @site = current_user.sites.build
    when :post
      @site = current_user.sites.build(_site_params)
      if @site.valid?
        SiteManager.new(@site).create
        redirect_to assistant_addons_path(@site), notice: t('flash.sites.create.notice')
      end
    end
  end

  # GET /assistant/:site_id/addons
  # PUT /assistant/:site_id/addons
  def addons
    if request.put? || request.patch?
      AddonsSubscriber.new(@site).update_billable_items(params[:designs], params[:addon_plans])

      redirect_to assistant_player_path(@site), notice: t('flash.addons.subscribe.notice')
    end
  end

  # GET /assistant/:site_id/player
  # PUT /assistant/:site_id/player
  def player
    if request.put? || request.patch?
      KitManager.new(@kit).save(_kit_params)

      redirect_to assistant_publish_video_path(@site)
    end
  end

  # GET /assistant/:site_id/publish-video
  def publish_video
  end

  # GET /assistant/:site_id/summary
  # POST /assistant/:site_id/summary
  def summary
    redirect_to sites_url if request.get?
  end

  private

  def _update_current_assistant_step_and_redirect
    if SiteSetupAssistant.step_number(action_name) < _assistant.current_step_number
      redirect_to send("assistant_#{_assistant.current_step}_path", @site)
    else
      @site.update_column(:current_assistant_step, action_name)
    end
  end

  def _assistant
    @assistant ||= SiteSetupAssistant.new(@site)
  end

  def _set_default_kit!
    @kit    = exhibit(@site.default_kit)
    @design = @kit.design
  end

  def _site_params
    params.require(:site).permit(:hostname)
  end

  def _kit_params
    params.require(:kit).permit(:name, :design_id).merge(settings: params[:kit][:settings])
  end

end
