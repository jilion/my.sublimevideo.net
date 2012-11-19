require_dependency 'stats_exporter'

class StatsExportsController < ApplicationController
  before_filter :redirect_suspended_user

  # GET /stats/exports/:id
  def show
    stats_export = StatsExport.find(params[:id])

    if stats_export.site.user == current_user
      redirect_to stats_export.file.secure_url
    else
      render nothing: true, status: :unauthorized
    end
  end

  # POST /stats/exports
  def create
    site_token, from, to = params[:stats_export].slice(:site_token, :from, :to).values

    if current_user.sites.where(token: site_token).exists?
      stats_exporter = StatsExporter.new(site_token, from.to_i, to.to_i)
      stats_exporter.delay(priority: 50).create_and_notify_export!
      render nothing: true
    else
      render nothing: true, status: :unauthorized
    end
  end

end
