#= require ./trend

class AdminSublimeVideo.Models.SiteStatsTrend extends AdminSublimeVideo.Models.Trend
  defaults:
    pv: {} # Page Visit
    vv: {} # Video views
    md: {} # Player Mode + Device hash
    bp: {} # Browser + Platform hash

  customGet: (selected) ->
    this.get(selected[0])[selected[1]] or 0

  html5Proportion: ->
    md = this.get('md')
    mdh = if md.h? then (md.h.d || 0) + (md.h.m || 0) + (md.h.t || 0) else 0
    mdf = if md.f? then (md.f.d || 0) + (md.f.m || 0) + (md.f.t || 0) else 0

    mdh / (mdh + mdf) * 100

  mobileProportion: ->
    md = this.get('md')
    mdd = if md.h? then (md.h.d || 0) else 0 + if md.f? then (md.f.d || 0) else 0
    mdm = if md.h? then (md.h.m || 0) + (md.h.t || 0) else 0 + if md.f? then (md.f.m || 0) + (md.f.t || 0) else 0

    mdm / (mdd + mdm) * 100

class AdminSublimeVideo.Collections.SiteStatsTrends extends AdminSublimeVideo.Collections.Trends
  model: AdminSublimeVideo.Models.SiteStatsTrend
  url: -> '/trends/site_stats.json'
  id: -> 'site_stats'
  yAxis: (selected) ->
    switch selected[0]
      when 'pv', 'vv' then 3
      when 'md' then 4
  chartType: (selected) ->
    switch selected[0]
      when 'pv', 'vv' then 'areaspline'
      when 'md' then 'spline'

  title: (selected) ->
    top = switch selected[0]
      when 'pv' then 'Page visits'
      when 'vv' then 'Video plays'
      else ''
    type = switch selected[1]
      when 'billable' then 'Billable '
      when 'm' then 'Main '
      when 'e' then 'Extra '
      when 'em' then 'Embed (Main & Extra embeds only) '
      when 'd' then 'Dev '
      when 'i' then 'Invalid '
      when 'html5_proportion' then 'HTML5'
      when 'mobile_proportion' then 'Mobile'
      else ''

    "#{type}#{top}"

  customPluck: (selected, from = null, to = null) ->
    array = []
    from  ||= this.at(0).id
    to    ||= this.at(this.length - 1).id

    while from <= to
      trend = this.get(from)
      value = if trend?
        switch selected[0]
          when 'pv', 'vv'
            switch selected[1]
              when 'all' then trend.customGet([selected[0], 'm']) + trend.customGet([selected[0], 'e']) + trend.customGet([selected[0], 'em']) + trend.customGet([selected[0], 'd']) + trend.customGet([selected[0], 'i'])

              when 'billable' then trend.customGet([selected[0], 'm']) + trend.customGet([selected[0], 'e']) + trend.customGet([selected[0], 'em'])

              else trend.customGet(selected)

          when 'md'
            switch selected[1]
              when 'html5_proportion' then trend.html5Proportion()
              when 'mobile_proportion' then trend.mobileProportion()
      else
        0

      array.push value
      from += 3600 * 24

    array
