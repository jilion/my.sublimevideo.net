class SVStats.Models.TweetsStat extends SVStats.Models.Stat
  defaults:
    k: {}

class SVStats.Collections.TweetsStats extends SVStats.Collections.Stats
  model: SVStats.Models.TweetsStat
  initialize: -> @selected = []
  url: -> '/stats/tweets.json'
  id: -> 'tweets'
  color: (selected) -> 'orange'

  title: (selected) ->
    switch selected[0]
      when 'jilion' then 'Jilion tweets'
      when 'sublimevideo' then 'SublimeVideo tweets'
      when 'aelios' then 'Aelios tweets'
      else selected[0]

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
