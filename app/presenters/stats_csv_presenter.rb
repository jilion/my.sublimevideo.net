require 'csv'

class StatsCsvPresenter

  attr_reader :object, :stats_presenter

  def initialize(object, stats_presenter)
    @object = object
    @stats_presenter = stats_presenter
  end

  def as_sent_file
    [_file.path, { filename: _filename, type: 'text/csv' }]
  end

  private

  def _filename
    raise NotImplementedError, "This #{self.class} cannot respond to: #{__method__}"
  end

  def _file
    tempfile = Tempfile.new(['export', '.csv'])
    CSV.open(tempfile, 'wb') do |csv|
      csv << %w[time loads plays]
      stats_presenter.loads.each_with_index do |(time, loads), i|
        csv << [Time.at(time / 1000), loads, stats_presenter.plays[i].last]
      end
    end

    tempfile
  end

end
