module Admin::StatsHelper
  
  def video_pageviews_per_day(start_time)
    Stat::Global.where(:day => { "$gte" => start_time.beginning_of_day.utc, "$ne" => nil }).only("vpv.new").order_by([[:day, :asc]])
    
    # Rails.cache.fetch("video_pageviews_per_minute", :expires_in => 5.minutes) do
    #   SiteUsage.collection.group(
    #     "function(x) {
    #       return { 'day' : new Date(x.started_at.getFullYear(), x.started_at.getMonth(), x.started_at.getDate()) };
    #     }", # key used to group
    #     { 
    #      :started_at => { "$gte" => start_time.utc }, # conditions
    #      :player_hits => { "$gt" => 0 }               # conditions
    #     },
    #     { :vpv => { "new" => 0 }, # memo variable name and initial value
    #     "function(doc, prev) { prev.vpv['new'] += doc.player_hits; }" # reduce function
    #   )
    # end
  end
  
end