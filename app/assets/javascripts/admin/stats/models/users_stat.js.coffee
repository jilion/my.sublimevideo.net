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

  initialize: ->
    @selected = 'active'

  url: -> "/stats/users.json"

  chartType: -> 'line'

  color: -> 'blue'

  id: -> 'users'

  title: ->
    switch @selected
      when 'fr' then 'Free users'
      when 'pa' then 'Paying users'
      when 'su' then 'Suspended users'
      when 'ar' then 'Archived users'
      when 'active' then 'Active users (free or paying)'
      when 'passive' then 'Passive users (suspended or archived)'
      else 'Users'

  startTime: -> this.at(0).time()

  customPluck: ->
    array = []
    from  = this.at(0).id
    to    = this.at(this.length - 1).id

    while from <= to
      stat = this.get(from)
      value = if stat?
        switch @selected
          when 'all' then stat.get('fr') + stat.get('pa') + stat.get('su') + stat.get('ar')
          when 'active' then stat.get('fr') + stat.get('pa')
          when 'passive' then stat.get('su') + stat.get('ar')
          else stat.get(@selected)
      else
        0
      array.push value
      from += 3600 * 24

    array
