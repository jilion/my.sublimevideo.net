#= require ./trend

class AdminSublimeVideo.Models.TweetsTrend extends AdminSublimeVideo.Models.Trend
  defaults:
    k: {}

class AdminSublimeVideo.Collections.TweetsTrends extends AdminSublimeVideo.Collections.Trends
  model: AdminSublimeVideo.Models.TweetsTrend
  url: -> '/trends/tweets.json'
  id: -> 'tweets'
  yAxis: (selected) -> 2

  title: (selected) ->
    switch selected[0]
      when 'sublimevideo' then 'SublimeVideo tweets'
      else "#{SublimeVideo.Misc.Utils.capitalize(selected[0])} tweets"

  customPluck: (selected, from = null, to = null) ->
    array = []
    from  ||= this.at(0).id
    to    ||= this.at(this.length - 1).id

    while from <= to
      trend = this.get(from)

      value = if trend?
        if trend.get('k')[selected[0]] then trend.get('k')[selected[0]] else 0
      else
        0

      array.push value
      from += 3600 * 24

    array
