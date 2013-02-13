require 'tempfile'
require 'csv'

class StatsExporter
  attr_reader :site, :from, :to

  def self.create_and_notify_export(site_token, from, to)
    exporter = new(site_token, from, to)
    exporter.create_and_notify_export
  end

  def initialize(site_token, from, to)
    @site = Site.where(token: site_token).first
    @from, @to = from, to
  end

  def create_and_notify_export
    with_tempfile_csv_export do |csv_export|
      stats_export = StatsExport.create!(
        site_token: site.token,
        from: from,
        to: to,
        file: csv_export
      )
      StatsExportMailer.export_ready(stats_export).deliver!
      Librato.increment 'stats.export'
    end
  end

  def with_tempfile_csv_export
    tempfile = Tempfile.new(['export', '.csv'])
    begin
      CSV.open(tempfile, "wb") do |csv|
        csv << ['uid', 'name', 'loads_count', 'views_count', 'embed_loads_count', 'embed_views_count']
        site.video_tags.active.each do |video_tag|
          stats = Stat::Video::Day.where(st: site.token, u: video_tag.uid).between(d: from..to).entries
          vl = hashes_values_sum(stats, :vl)
          vv = hashes_values_sum(stats, :vv)
          csv << [video_tag.uid, video_tag.name, vl['m'].to_i + vl['e'].to_i, vv['m'].to_i + vv['e'].to_i, vl['em'].to_i, vv['em'].to_i]
        end
      end
      yield(tempfile)
    ensure
      tempfile.close
      tempfile.unlink
    end
  end

private

  def hashes_values_sum(stats, attribute)
    stats.map(&attribute).inject({}) do |memo, el|
      memo.merge(el) { |k, old_v, new_v| old_v + new_v }
    end
  end

end
