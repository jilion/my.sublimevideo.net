class Stat

  # ====================
  # = Instance Methods =
  # ====================
  def self.usages(start_date, end_date, options={})
    conditions = {
      :day => {
        "$gte" => start_date.midnight,
        "$lt"  => end_date.end_of_day
      }
    }
    conditions[:site_id] = options[:site_id].to_i if options[:site_id]

    SiteUsage.collection.group(
      :key => [:day],
      :cond => conditions,
      :initial => { :loader_usage => 0,
        :invalid_usage => 0, :invalid_usage_cached => 0,
        :dev_usage => 0, :dev_usage_cached => 0,
        :main_usage => 0, :main_usage_cached => 0,
        :all_usage => 0 }, # memo variable name and initial value
      :reduce => "function(doc, prev) {
        prev.loader_usage         += doc.loader_hits;
        prev.invalid_usage        += doc.invalid_player_hits;
        prev.invalid_usage_cached += doc.invalid_player_hits_cached;
        prev.dev_usage            += doc.dev_player_hits;
        prev.dev_usage_cached     += doc.dev_player_hits_cached;
        prev.main_usage           += doc.main_player_hits;
        prev.main_usage_cached    += doc.main_player_hits_cached;
        prev.all_usage            += doc.player_hits;
      }" # reduce function
    )
  end

end