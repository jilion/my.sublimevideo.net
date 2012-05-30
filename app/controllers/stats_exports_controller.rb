class StatsExportsController < ApplicationController
  before_filter :redirect_suspended_user

  # GET /stats/export/:id
  def show
    stats_export = StatsExport.find(params[:id])

    if stats_export.site.user == current_user
      redirect_to stats_export.file.secure_url
    else
      render nothing: true, status: :unauthorized
    end
  end

  # POST /stats/export
  def create
    site_token, from, to = params[:stats_export].slice(:st, :from, :to).values

    if current_user.sites.where(token: site_token).exists?
      stats_exporter = StatsExporter.new(site_token, from, to)
      stats_exporter.delay(priority: 50).create_and_notify_export!
      render nothing: true
    else
      render nothing: true, status: :unauthorized
    end
  end

end