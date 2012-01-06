class SVStats.Models.SiteStatsStat extends SVStats.Models.Stat
  defaults:
    pv: {} # Page Visit
    vv: {} # Video views
    md: {} # Player Mode + Device hash
    bp: {} # Browser + Plateform hash

  customGet: (selected) ->
    this.get(selected[0])[selected[1]] || 0
    
  html5Proportion: ->
    md = this.get('md')
    mdh = if md.h? then (md.h.d || 0) + (md.h.m || 0) + (md.h.t || 0) else 0  
    mdf = if md.f? then (md.f.d || 0) + (md.f.m || 0) + (md.f.t || 0) else 0
    console.log mdh
    console.log mdf
    mdh / (mdh + mdf)
    
  mobileProportion: ->
    md = this.get('md')
    mdd = if md.h? then (md.h.d || 0) else 0 + if md.f? then (md.f.d || 0) else 0
    mdm = if md.h? then (md.h.m || 0) + (md.h.t || 0) else 0 + if md.f? then (md.f.m || 0) + (md.f.t || 0) else 0  
    console.log mdd
    console.log mdm
    mdm / (mdd + mdm)

class SVStats.Collections.SiteStatsStats extends SVStats.Collections.Stats
  model: SVStats.Models.SiteStatsStat
  initialize: -> @selected = ['pv.billable', 'vv.billable', 'md.html5_proportion']
  url: -> '/stats/site_stats.json'
  id: -> 'site_stats'
  color: -> 'rgba(100,100,200,0.5)'
  
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
      when 'billable' then 'Billable'
      when 'm' then 'Main'
      when 'e' then 'Extra'
      when 'em' then 'Embed (Main & Extra embeds only)'
      when 'd' then 'Dev'
      when 'i' then 'Invalid'
      when 'html5_proportion' then 'HTML5 proportion'
      when 'mobile_proportion' then 'Mobile (tablet included) proportion'
    "#{type} #{top}"

  customPluck: (selected) ->
    array = []
    from  = this.at(0).id
    to    = this.at(this.length - 1).id
    while from <= to
      stat = this.get(from)
      value = if stat?
        switch selected[0]
          when "pv", 'vv'
            switch selected[1]
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
