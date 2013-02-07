require_dependency 'service/site'
require_dependency 'service/kit'

class AssistantController < ApplicationController
  before_filter :find_sites
  before_filter :find_site_by_token!, :update_current_assistant_step_and_redirect, except: [:new_site]
  before_filter :set_current_assistant_step_to_player_and_redirect_if_addons_already_updated, except: [:new_site]
  before_filter :find_default_kit!, only: [:player, :publish_video]

  # GET /assistant/new-site
  # POST /assistant/new-site
  def new_site
    @site = current_user.sites.build(params[:site])
    if request.post?
      if @site.valid?
        Service::Site.new(@site).create
        redirect_to assistant_addons_path(@site), notice: t('flash.sites.create.notice')
      end
    end
  end

  # GET /assistant/:site_id/addons
  # PUT /assistant/:site_id/addons
  def addons
    if request.put?
      Service::Site.new(@site).update_billable_items(params[:app_designs], params[:addon_plans])

      redirect_to assistant_player_path(@site), notice: t('flash.addons.update_all.notice')
    end
  end

  # GET /assistant/:site_id/player
  # PUT /assistant/:site_id/player
  def player
    if request.put?
      Service::Kit.new(@kit).save(params[:kit])

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

  def update_current_assistant_step_and_redirect
    if SiteSetupAssistant.step_number(action_name) < assistant.current_step_number
      redirect_to send("assistant_#{assistant.current_step}_path", @site)
    else
      @site.update_column(:current_assistant_step, action_name)
    end
  end

  def set_current_assistant_step_to_player_and_redirect_if_addons_already_updated
    if @site.addons_updated_at? && assistant.current_step_number < 3
      @site.update_column(:current_assistant_step, 'player')
      redirect_to assistant_player_path(@site)
    end
  end

  def assistant
    @assistant ||= SiteSetupAssistant.new(@site)
  end

  def find_default_kit!
    @kit    = exhibit(@site.default_kit)
    @design = @kit.design
  end

end
