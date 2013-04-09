require 'has_scope'

class PrivateApi::SitesController < SublimeVideoPrivateApiController
  has_scope :with_state, :created_on, :not_tagged_with, :by_date
  has_scope :with_min_billable_video_views, :first_billable_plays_on_week
  has_scope :select, :without_hostnames, type: :array

  # GET /private_api/sites
  def index
    @sites = Site.page(params[:page])
    @sites.includes(*params[:includes]) if params[:includes]

    respond_with(apply_scopes(@sites))
  end

  # GET /private_api/sites/:id
  def show
    @site = Site.where(token: params[:id]).first!

    respond_with(@site)
  end

  # PUT /private_api/sites/:id/add_tag
  def add_tag
    @site = Site.where(token: params[:id]).first!
    @site.tag_list << params[:tag]
    @site.save!

    respond_with(@site)
  end
end
