#= require ./trend

class AdminSublimeVideo.Models.UsersTrend extends AdminSublimeVideo.Models.Trend
  defaults:
    be: 0 # beta
    fr: 0 # free
    pa: 0 # paying
    su: 0 # suspended
    ar: 0 # archived

class AdminSublimeVideo.Collections.UsersTrends extends AdminSublimeVideo.Collections.Trends
  model: AdminSublimeVideo.Models.UsersTrend
  url: -> '/trends/users.json'
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
      trend = this.get(from)
      value = if trend?
        switch selected[0]
          when 'all' then trend.get('be') + trend.get('fr') + trend.get('pa') + trend.get('su') + trend.get('ar')
          when 'active' then trend.get('be') + trend.get('fr') + trend.get('pa')
          when 'passive' then trend.get('su') + trend.get('ar')
          else trend.get(selected[0])
      else
        0

      array.push value
      from += 3600 * 24

    array
