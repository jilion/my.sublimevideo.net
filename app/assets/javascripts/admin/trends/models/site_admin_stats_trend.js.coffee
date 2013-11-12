#= require ./trend

class AdminSublimeVideo.Models.SiteAdminStatsTrend extends AdminSublimeVideo.Models.Trend
  defaults:
    al: {} # App loads
    lo: {} # Video loads
    st: {} # Video starts

  customGet: (selected) ->
    this.get(selected[0])[selected[1]] or 0

class AdminSublimeVideo.Collections.SiteAdminStatsTrends extends AdminSublimeVideo.Collections.Trends
  model: AdminSublimeVideo.Models.SiteAdminStatsTrend
  url: -> '/trends/site_admin_stats.json'
  id: -> 'site_admin_stats'
  yAxis: (selected) -> 3
  chartType: (selected) -> 'areaspline'

  title: (selected) ->
    env = switch selected[1]
      when 'production' then 'Production '
      when 'development' then 'Development '
      when 'ex' then 'External '
      when 'i' then 'Invalid '
      when 'w' then 'Website '
      when 'e' then 'External '
      else ''
    hit_kind = switch selected[0]
      when 'al' then 'App loads'
      when 'lo' then 'Video loads'
      when 'st' then 'Video starts'
      else ''

    "#{env}#{hit_kind}"

  customPluck: (selected, from = null, to = null) ->
    array = []
    from  ||= this.at(0).id
    to    ||= this.at(this.length - 1).id

    while from <= to
      trend = this.get(from)
      value = if trend?
        switch selected[0]
          when 'al'
            switch selected[1]
              when 'all' then trend.customGet([selected[0], 'm']) + trend.customGet([selected[0], 'e']) + trend.customGet([selected[0], 'd']) + trend.customGet([selected[0], 'i'])
              when 'production' then trend.customGet([selected[0], 'm']) + trend.customGet([selected[0], 'e'])
              when 'development' then trend.customGet([selected[0], 'd']) + trend.customGet([selected[0], 's'])
              else trend.customGet(selected)

          when 'lo', 'st'
            switch selected[1]
              when 'all' then trend.customGet([selected[0], 'w']) + trend.customGet([selected[0], 'e'])
              else trend.customGet(selected)
      else
        0

      array.push value
      from += 3600 * 24

    array
