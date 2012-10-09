#= require ./stat

class AdminSublimeVideo.Models.UsersStat extends AdminSublimeVideo.Models.Stat
  defaults:
    be: 0 # beta
    fr: 0 # free
    pa: 0 # paying
    su: 0 # suspended
    ar: 0 # archived

class AdminSublimeVideo.Collections.UsersStats extends AdminSublimeVideo.Collections.Stats
  model: AdminSublimeVideo.Models.UsersStat
  url: -> '/stats/users.json'
  id: -> 'users'
  yAxis: (selected) -> 1

  title: (selected) ->
    if selected.length == 1
      switch selected[0]
        when 'be' then 'Beta users'
        when 'fr' then 'Free users'
        when 'pa' then 'Paying users'
        when 'su' then 'Suspended users'
        when 'ar' then 'Archived users'
        when 'active' then 'Active users'
        when 'passive' then 'Passive users'
        when 'all' then 'Users'

  customPluck: (selected, from = null, to = null) ->
    array = []
    from  ||= this.at(0).id
    to    ||= this.at(this.length - 1).id

    while from <= to
      stat = this.get(from)
      value = if stat?
        switch selected[0]
          when 'all' then stat.get('be') + stat.get('fr') + stat.get('pa') + stat.get('su') + stat.get('ar')
          when 'active' then stat.get('be') + stat.get('fr') + stat.get('pa')
          when 'passive' then stat.get('su') + stat.get('ar')
          else stat.get(selected[0])
      else
        0

      array.push value
      from += 3600 * 24

    array
