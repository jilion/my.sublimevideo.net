#= require ./stat

class AdminSublimeVideo.Models.SalesStat extends AdminSublimeVideo.Models.Stat
  defaults:
    ne: 0 # new
    re: 0 # renew

class AdminSublimeVideo.Collections.SalesStats extends AdminSublimeVideo.Collections.Stats
  model: AdminSublimeVideo.Models.SalesStat
  url: -> '/stats/sales.json'
  id: -> 'sales'
  chartType: (selected) -> 'column'
  yAxis: (selected) -> 0

  title: (selected) ->
    if selected.length > 1 # attribute is something like: ["ne", "premium"] or ["ne", "premium", "y"]
      text = "Sales "
      text += "from "
      if selected.length > 2 # attribute is something like: ["ne", "premium", "y"]
        text += if selected[2] == "y" then "yearly " else "monthly "
      text += "#{SublimeVideo.capitalize(selected[1])} plan "
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
          v = stat.get(selected[0])
          _.each _.rest(selected), (e) -> if v[e]? then v = v[e] else v = 0
          this.recursiveHashSum(v)

        else if !_.isEmpty(_.values(stat.get(selected[0])))
          this.recursiveHashSum(stat.get(selected[0]) or 0)

        else if selected[0] is 'total'
          this.recursiveHashSum(stat.get('ne') or 0) + this.recursiveHashSum(stat.get('re') or 0)

        else
          v = stat.get(selected[0])
          if _.isEmpty(v) then 0 else v

      else
        0

      array.push value / 100
      from += 3600 * 24

    array
