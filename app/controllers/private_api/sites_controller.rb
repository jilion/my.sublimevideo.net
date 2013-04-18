require 'has_scope'

class PrivateApi::SitesController < SublimeVideoPrivateApiController
  before_filter :find_site_by_token!, only: [:show, :add_tag]

  has_scope :per, :with_state, :created_on, :created_after, :not_tagged_with, :by_date,
            :with_min_billable_video_views, :first_billable_plays_on_week
  has_scope :select, :without_hostnames, type: :array
  has_scope :not_archived, type: :boolean

  # GET /private_api/sites
  def index
    respond_with(apply_scopes(Site.page(params[:page])))
  end

  # GET /private_api/sites/:id
  def show
    respond_with(@site)
  end

  # PUT /private_api/sites/:id/add_tag
  before_filter(only: :add_tag) { |controller| controller.required_params!(:tag) }
  def add_tag
    @site.tag_list << params[:tag]
    @site.save!

    respond_with(@site)
  end

  def required_params!(*param_keys)
    present_params_keys = params.select { |k, v| param_keys.include?(k.to_sym) && v.present? }.keys.map(&:to_sym)

    unless present_params_keys.size == param_keys.size
      body = { error: "Missing #{list_of_params_as_string(param_keys - present_params_keys)} parameters." }
      render(json: body, status: 400) and return
    end
  end

  private

  def find_site_by_token!
    @site = apply_scopes(Site.find_by_token!(params[:id]))
  end

  def list_of_params_as_string(list)
    list.map { |p| ":#{p}" }.join(', ')
  end
end
