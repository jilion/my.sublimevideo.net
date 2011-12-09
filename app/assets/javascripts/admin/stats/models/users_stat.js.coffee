class SVStats.Models.UsersStat extends Backbone.Model
  defaults:
    fr: 0 # free
    pa: 0 # paying
    su: 0 # suspended
    ar: 0 # archived

  time: ->
    parseInt(this.id) * 1000

  date: ->
    new Date(this.time())

class SVStats.Collections.UsersStats extends Backbone.Collection
  model: SVStats.Models.UsersStat

  url: -> "/stats/users.json"

  chartType: -> 'line'

  startTime: ->
    _.min(@models, (m) -> m.id).time()

  endTime: ->
    _.max(@models, (m) -> m.id).time()

  customPluck: (attribute) ->
    array = []
    # from  = this.at(0).id # SVStats.period.get('startSecondsTime') / 1000
    # to    = this.at(this.size() - 1).id # SVStats.period.get('endSecondsTime') / 1000
    from  = _.min(@models, (m) -> m.id).id # SVStats.period.get('startSecondsTime') / 1000
    to    = _.max(@models, (m) -> m.id).id # SVStats.period.get('endSecondsTime') / 1000

    while from <= to
      stat = this.get(from)
      array.push(if stat? then stat.get(attribute) else 0)
      from += 3600 * 24

    array
