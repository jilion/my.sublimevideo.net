class SVStats.Models.TweetsStat extends Backbone.Model
  defaults:
    total: 0

  time: ->
    parseInt(this.id) * 1000

  date: ->
    new Date(this.time())

class SVStats.Collections.TweetsStats extends Backbone.Collection
  model: SVStats.Models.TweetsStat

  initialize: ->
    @selected = 'sublimevideo'

  url: -> '/stats/tweets.json'

  chartType: -> 'line'

  color: -> 'green'

  id: -> 'tweets'

  title: ->
    switch @selected
      when 'sublimevideo' then 'SublimeVideo tweets'

  startTime: -> this.at(0).time() + 3600 * 24 * 1000

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
