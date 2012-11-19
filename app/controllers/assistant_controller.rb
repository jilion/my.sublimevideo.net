require_dependency 'service/assistant'

class AssistantController < ApplicationController
  before_filter :find_sites_or_redirect_to_new_site, :find_site_by_token!, :update_current_assistant_step_and_redirect
  before_filter :find_default_kit!, only: [:player, :publish_video]

  # GET /assistant/:site_id/addons
  # PUT /assistant/:site_id/addons
  def addons
    if request.put?
      redirect_to assistant_player_url
    end
  end

  # GET /assistant/:site_id/player
  # PUT /assistant/:site_id/player
  def player
    if request.put?
      redirect_to assistant_publish_video_url
    end
  end

  # GET /assistant/:site_id/publish_video
  def publish_video
  end

  # GET /assistant/:site_id/summary
  def summary
    # redirect_to :sites
  end

  private

  def update_current_assistant_step_and_redirect
    assistant = Service::Assistant.new(@site)
    if @site.addons_updated_at && assistant.current_step_number < 3
      @site.update_column(:current_assistant_step, 'player')
      redirect_to assistant_player_url
    else
      @site.update_column(:current_assistant_step, action_name)
    end
  end

  def find_default_kit!
    @kit = exhibit(@site.default_kit)
  end

end
