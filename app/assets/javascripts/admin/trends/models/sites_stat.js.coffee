#= require ./trend

class AdminSublimeVideo.Models.SitesTrend extends AdminSublimeVideo.Models.Trend
  defaults:
    fr: {} # free
    tr: 0 # trial
    pa: {} # paying
    su: 0 # suspended
    ar: 0 # archived

class AdminSublimeVideo.Collections.SitesTrends extends AdminSublimeVideo.Collections.Trends
  model: AdminSublimeVideo.Models.SitesTrend
  url: -> '/trends/sites.json'
  id: -> 'sites'
  yAxis: (selected) -> 1

  title: (selected) ->
    if selected.length > 1 # attribute is something like: ["pa", "premium"] or ["pa", "premium", "y"]
      text = "Sites "
      if selected[1] is 'addons'
        text += "with add-ons"
      else
        text += "with the"
        if selected.length > 2 # attribute is something like: ["pa", "premium", "y"]
          text += if selected[2] == "y" then " yearly " else " monthly "
        text += "#{SublimeVideo.Misc.Utils.capitalize(selected[1])} plan"
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

  customPluck: (selected, from = null, to = null) ->
    array = []
    from  ||= this.at(0).id
    to    ||= this.at(this.length - 1).id

    while from <= to
      trend = this.get(from)

      value = if trend?
        if selected.length > 1 # attribute is something like: ["pa", "premium"]
          value = trend.get(selected[0])
          _.each _.rest(selected), (e) -> if value[e]? then value = value[e] else value = 0
          this.recursiveHashSum(value)
        else if !_.isEmpty(_.values(trend.get(selected[0])))
          this.recursiveHashSum(trend.get(selected[0]))
        else
          switch selected[0]
            when 'all' then this.recursiveHashSum(trend.get('fr')) + this.recursiveHashSum(trend.get('sp')) + trend.get('tr') + this.recursiveHashSum(trend.get('pa')) + trend.get('su') + trend.get('ar')

            when 'active' then this.recursiveHashSum(trend.get('fr')) + this.recursiveHashSum(trend.get('sp')) + trend.get('tr') + this.recursiveHashSum(trend.get('pa'))

            when 'passive' then trend.get('su') + trend.get('ar')

            else trend.get(selected[0])
      else
        0

      array.push value
      from += 3600 * 24

    array
