class SVStats.Models.TweetsStat extends SVStats.Models.Stat
  defaults:
    total: 0

class SVStats.Collections.TweetsStats extends SVStats.Collections.Stats
  model: SVStats.Models.TweetsStat
  initialize: -> @selected = 'sublimevideo'
  url: -> '/stats/tweets.json'
  id: -> 'tweets'
  color: -> 'rgba(0,255,0,0.5)'

  title: ->
    switch @selected
      when 'jilion' then 'Jilion tweets'
      when 'sublimevideo' then 'SublimeVideo tweets'
      when 'aelios' then 'Aelios tweets'

  startTime: -> this.at(0).time() + (3600 * 24 * 1000) # we add one day to be sure we have only full day stats

  customPluck: ->
    array = []
    from  = this.at(0).id
    to    = this.at(this.length - 1).id
    last_total = 0

    while from <= to
      stat = this.get(from)

      value = if stat?
        last_total = stat.get('total')
      else
        last_total
      array.push value
      from += 3600 * 24

    array
