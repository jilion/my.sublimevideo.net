require 'has_scope'

class PrivateApi::SitesController < SublimeVideoPrivateApiController
  before_filter :_set_sites, only: [:index]
  before_filter :_set_site, only: [:show, :add_tag]

  has_scope :per, :created_on, :created_after, :not_tagged_with, :by_date, :with_addon_plan,
            :with_min_billable_video_views, :first_billable_plays_on_week, :user_id
  has_scope :select, :without_hostnames, type: :array
  has_scope :not_archived, type: :boolean

  # GET /private_api/sites
  def index
    expires_in 2.minutes, public: true
    respond_with(@sites)
  end

  # GET /private_api/sites/tokens
  def tokens
    @sites = apply_scopes(Site.with_state('active'))
    expires_in 2.minutes, public: true
    respond_with(@sites.pluck(:token))
  end

  # GET /private_api/sites/:id
  def show
    expires_in 2.minutes, public: true
    respond_with(@site) if stale?(@site)
  end

  # PUT /private_api/sites/:id/add_tag
  def add_tag
    @site.tag_list << _tag_params
    @site.save!

    respond_with(@site)
  end

  private

  def _set_sites
    @sites = apply_scopes(_base_scopes.page(params[:page]))
  end

  def _set_site
    @site = apply_scopes(_base_scopes).where(token: params[:id]).first!
  end

  def _tag_params
    params.require(:tag)
  end

  def _base_scopes
    scopes = Site.with_state('active').order(:created_at).includes(:default_kit).references(:kits)
    scopes = scopes.select(:default_kit_id) if params['select']
    scopes
  end

end
