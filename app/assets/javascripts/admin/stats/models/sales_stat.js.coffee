#= require ./stat

class AdminSublimeVideo.Models.SalesStat extends AdminSublimeVideo.Models.Stat
  defaults:
    ne: {} # new
    re: {} # renew

class AdminSublimeVideo.Collections.SalesStats extends AdminSublimeVideo.Collections.Stats
  model: AdminSublimeVideo.Models.SalesStat
  url: -> '/stats/sales.json'
  id: -> 'sales'
  chartType: (selected) -> 'spline'
  yAxis: (selected) -> 0

  title: (selected) ->
    if selected.length > 1 # attribute is something like: ["ne", "premium"] or ["ne", "premium", "y"]
      text = "Sales "
      text += "from "
      if selected.length > 2 # attribute is something like: ["ne", "premium", "y"]
        text += if selected[2] == "y" then "yearly " else "monthly "
      text += "#{selected[1].capitalize()} plan "
      switch selected[0]
        when 'ne' then text += 'subscription'
        when 're' then text += 'renewing'
      text
    else
      switch selected[0]
        when 'ne' then 'Sales from new subscription'
        when 're' then 'Sales from renewing'
        when 'total' then 'Total sales (from new subscription & renewing)'

  customPluck: (selected) ->
    array = []
    from  = this.at(0).id
    to    = this.at(this.length - 1).id

    while from <= to
      stat = this.get(from)

      value = if stat?
        if selected.length > 1 # attribute is something like: ["ne", "premium"] or ["ne", "premium", "y"]
          value = stat.get(selected[0])
          _.each _.rest(selected), (e) -> if value[e]? then value = value[e] else value = 0
          this.recursiveHashSum(value)
        else if !_.isEmpty(_.values(stat.get(selected[0])))
          this.recursiveHashSum(stat.get(selected[0]))
        else if selected[0] is 'total'
          this.recursiveHashSum(stat.get('ne')) + this.recursiveHashSum(stat.get('re'))
      else
        0
      array.push value / 100
      from += 3600 * 24

    array
