class TweetsStat

  def self.json(options = {})
    conditions = {}
    conditions[:keywords] = { "$in" => Array.wrap(options[:keyword]) } if options[:keyword]

    stats = Tweet.collection.map_reduce(
      "function(){
        emit(Date.UTC(this.tweeted_at.getFullYear(), this.tweeted_at.getMonth(), this.tweeted_at.getDate()), 1);
      }",
      "function(key, vals){
        var total = 0;
        for(var i in vals) total += vals[i];
        return total;
      };",
      {
        query: conditions,
        raw: true,
        out: { inline: 1 },
        sort: [[:_id, :asc]]
      }
    )

    # puts stats['results'].inspect
    results = []
    stats['results'].inject(0) do |sum, stat|
      sum += stat['value'].to_i
      results << { 'id' => (stat['_id'].to_i / 1000), 'total' => sum }
      sum
    end
    results
  end

end
