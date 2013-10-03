class VideoStatsCsvPresenter < StatsCsvPresenter

  private

  def _filename
    "video_stats-#{object.uid}-#{stats_presenter.options[:source]}-#{stats_presenter.options[:hours].to_i.hours.ago.change(min: 0)}-#{1.hour.ago.change(min: 0)}.csv"
  end

end
