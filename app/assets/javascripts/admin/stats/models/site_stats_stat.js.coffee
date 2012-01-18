class SVStats.Models.SiteStatsStat extends SVStats.Models.Stat
  defaults:
    pv: {} # Page Visit
    vv: {} # Video views
    md: {} # Player Mode + Device hash
    bp: {} # Browser + Plateform hash

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

class SVStats.Collections.SiteStatsStats extends SVStats.Collections.Stats
  model: SVStats.Models.SiteStatsStat
  initialize: -> @selected = ['vv.billable'] # ['pv.billable', 'vv.billable', 'md.html5_proportion']
  url: -> '/stats/site_stats.json'
  chartType: (selected) ->
    switch selected[0]
      when 'pv', 'vv' then 'areaspline'
      when 'md' then 'line'

  id: -> 'site_stats'

  fillColor: (selected) ->
    switch selected[0]
      when 'pv' then 'rgba(74,100,142,0.3)'
      when 'vv' then 'rgba(9,250,33,0.15)'
      when 'md' then 'rgba(250,150,100,0.7)'

  color: (selected) ->
    switch selected[0]
      when 'pv' then '#596e8c'
      when 'vv' then '#00ff18'
      when 'md' then 'rgba(250,150,100,0.7)'

  lineColor: (selected) ->
    switch selected[0]
      when 'pv' then '#596e8c'
      when 'vv' then '#00ff18'
      when 'md' then 'rgba(250,150,100,0.7)'

  shadow: (selected) ->
    switch selected[0]
      when 'vv' then true
      else false

  yAxis: (selected) ->
    switch selected[0]
      when 'pv', 'vv' then 1
      when 'md' then 2

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

  customPluck: (selected) ->
    array = []
    from  = this.at(0).id
    to    = this.at(this.length - 1).id
    while from <= to
      stat = this.get(from)
      value = if stat?
        switch selected[0]
          when 'pv', 'vv'
            switch selected[1]
              when 'all' then stat.customGet([selected[0], 'm']) + stat.customGet([selected[0], 'e']) + stat.customGet([selected[0], 'em']) + stat.customGet([selected[0], 'd']) + stat.customGet([selected[0], 'i'])
              when 'billable' then stat.customGet([selected[0], 'm']) + stat.customGet([selected[0], 'e']) + stat.customGet([selected[0], 'em'])
              else stat.customGet(selected)
          when 'md'
            switch selected[1]
              when 'html5_proportion' then stat.html5Proportion()
              when 'mobile_proportion' then stat.mobileProportion()
      else
        0
      array.push value
      from += 3600 * 24

    array
