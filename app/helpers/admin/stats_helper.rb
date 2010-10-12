module Admin::StatsHelper
  
  def site_usages_chart_series(site_usages, start_time)
    site_usages_by_day = site_usages.started_after(start_time.beginning_of_day).
                                     where(:player_hits => { "$gt" => 1 }).
                                     only(:created_at, :player_hits).to_a#.
                                     # limit((Time.now.to_i - start_time.to_i)/(3600*24))
    
    #puts site_usages_by_day.first.created_at.beginning_of_day
    (start_time.to_date..Date.today).inject([]) do |hits_count, date|
      (0..23).each do |hour|
        site_usages_for_date = site_usages_by_day.select do |site_usage|
          site_usage.created_at.change(:min => 0, :sec => 0) == date.to_time.change(:hour => hour, :min => 0, :sec => 0)
        end
        hits_count << (site_usages_for_date.sum(&:player_hits) || 0)
      end
      hits_count
    end.inspect
  end
  
end