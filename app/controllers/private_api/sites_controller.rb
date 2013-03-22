require 'has_scope'

class PrivateApi::SitesController < SublimeVideoPrivateApiController
  has_scope :active, :per, :with_min_billable_video_views, :created_on, :first_billable_plays_on_week, :tagged_with
  has_scope :first_billable_plays_on
  has_scope :select, :without_hostnames, type: :array

  def index
    @sites = apply_scopes(Site.page(params[:page]))

    respond_with(@sites)
  end

  def show
    @site = Site.where(token: params[:id]).first!

    respond_with(@site)
  end
end
