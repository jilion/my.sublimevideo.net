class SiteStatsCsvPresenter < StatsCsvPresenter

  private

  def _filename
    "site_stats-#{object.token}-#{stats_presenter.options[:source]}-#{stats_presenter.options[:hours].to_i.hours.ago.change(min: 0)}-#{1.hour.ago.change(min: 0)}.csv"
  end

end
