#= require ./stat

class AdminSublimeVideo.Models.SitesStat extends AdminSublimeVideo.Models.Stat
  defaults:
    fr: {} # free
    tr: {} # trial
    pa: {} # paying
    su: 0 # suspended
    ar: 0 # archived

class AdminSublimeVideo.Collections.SitesStats extends AdminSublimeVideo.Collections.Stats
  model: AdminSublimeVideo.Models.SitesStat
  url: -> '/stats/sites.json'
  id: -> 'sites'
  color: (selected) -> 'rgba(255,0,0,0.7)'
  shadow: (selected) -> true

  title: (selected) ->
    if selected.length > 1
      text = "Sites "
      if selected.length > 1 # attribute is something like: ["tr", "premium", "y"]
        text += "in trial " if selected[0] == "tr"
        text += "with the "
        if selected.length > 2
          text += if selected[2] == "y" then "yearly " else "monthly "
      text += "#{selected[1]} plan"
      text
    else
      switch selected[0]
        when 'sp' then 'Sponsored sites'
        when 'tr' then 'Sites in trial'
        when 'pa' then 'Paying sites'
        when 'su' then 'Suspended sites'
        when 'ar' then 'Archived sites'
        when 'active' then 'Active sites'
        when 'passive' then 'Passive sites'
        when 'all' then 'Sites'

  customPluck: (selected) ->
    array = []
    from  = this.at(0).id
    to    = this.at(this.length - 1).id

    while from <= to
      stat = this.get(from)

      value = if stat?
        if selected.length > 1
          value = stat.get(selected[0])
          if selected.length > 1 # attribute is something like: ["tr", "premium", "y"]
            _.each _.rest(selected), (e) -> value = value[e]
            value = this.recursiveHashSum(value)
          value
        else if !_.isEmpty(_.values(stat.get(selected[0])))
          this.recursiveHashSum(stat.get(selected[0]))
        else
          switch selected[0]
            when 'all' then this.recursiveHashSum(stat.get('fr')) + this.recursiveHashSum(stat.get('tr')) + this.recursiveHashSum(stat.get('pa')) + stat.get('su') + stat.get('ar')
            when 'active' then this.recursiveHashSum(stat.get('fr')) + this.recursiveHashSum(stat.get('tr')) + this.recursiveHashSum(stat.get('pa'))
            when 'passive' then stat.get('su') + stat.get('ar')
            else stat.get(selected[0])
      else
        0
      array.push value
      from += 3600 * 24

    array
