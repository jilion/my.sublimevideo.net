module Admin::StatsHelper
  
  def site_usages_chart_series(site_usages, start_time)
    site_usages_by_day = site_usages.started_after(start_time.beginning_of_day).
                                     where(:player_hits => { "$gt" => 1 }).
                                     only(:created_at, :player_hits).to_a#.
                                     # limit((Time.now.to_i - start_time.to_i)/(3600*24))
    # puts site_usages_by_day.map(&:created_at).map(&:to_date).inspect
    (start_time.to_date..Date.today).map do |date|
      site_usage = site_usages_by_day.detect do |site_usage|
        # puts "site_usage.created_at.to_date: #{site_usage.created_at.to_date}"
        # puts "date: #{date}"
        # puts "#{site_usage.created_at.to_date} == #{date}: #{site_usage.created_at.to_date == date}"
        site_usage.created_at.to_date == date
      end
      # puts site_usage.inspect
      site_usage && site_usage.player_hits.to_i || 0
    end.inspect
  end
  
end