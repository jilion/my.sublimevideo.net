class SVStats.Models.UsersStat extends SVStats.Models.Stat
  defaults:
    fr: 0 # free
    pa: 0 # paying
    su: 0 # suspended
    ar: 0 # archived

class SVStats.Collections.UsersStats extends SVStats.Collections.Stats
  model: SVStats.Models.UsersStat
  url: -> '/stats/users.json'
  id: -> 'users'
  color: -> 'rgba(0,0,255,0.5)'

  title: ->
    switch @selected
      when 'fr' then 'Free users'
      when 'pa' then 'Paying users'
      when 'su' then 'Suspended users'
      when 'ar' then 'Archived users'
      when 'active' then 'Active users (free or paying)'
      when 'passive' then 'Passive users (suspended or archived)'
      else
        'Users'

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
