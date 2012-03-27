#= require ./stat

class AdminSublimeVideo.Models.TweetsStat extends AdminSublimeVideo.Models.Stat
  defaults:
    k: {}

class AdminSublimeVideo.Collections.TweetsStats extends AdminSublimeVideo.Collections.Stats
  model: AdminSublimeVideo.Models.TweetsStat
  url: -> '/stats/tweets.json'
  id: -> 'tweets'
  yAxis: (selected) -> 1

  title: (selected) ->
    switch selected[0]
      when 'sublimevideo' then 'SublimeVideo tweets'
      else "#{SublimeVideo.capitalize(selected[0])} tweets"

  customPluck: (selected) ->
    array = []
    from  = this.at(0).id
    to    = this.at(this.length - 1).id

    while from <= to
      stat = this.get(from)

      value = if stat?
        if stat.get('k')[selected[0]] then stat.get('k')[selected[0]] else 0
      else
        0

      array.push value
      from += 3600 * 24

    array
