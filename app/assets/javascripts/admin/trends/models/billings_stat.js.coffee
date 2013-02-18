#= require ./trend

class AdminSublimeVideo.Models.BillingsTrend extends AdminSublimeVideo.Models.Trend
  defaults:
    ne: 0 # new
    re: 0 # renew

class AdminSublimeVideo.Collections.BillingsTrends extends AdminSublimeVideo.Collections.Trends
  model: AdminSublimeVideo.Models.BillingsTrend
  url: -> '/trends/billings.json'
  id: -> 'billings'
  chartType: (selected) -> 'column'
  yAxis: (selected) -> 0

  title: (selected) ->
    if selected.length > 1 # attribute is something like: ["ne", "premium"] or ["ne", "premium", "y"]
      text = switch selected[0]
        when 'ne' then text += 'New'
        when 're' then text += 'Renew'

      if selected.length > 2 # attribute is something like: ["ne", "logo", "disabled"]
        text += "#{SublimeVideo.Misc.Utils.capitalize(selected[1])} (#{SublimeVideo.Misc.Utils.capitalize(selected[2])}) add-on"
      else
        text += if _.contains(['comet', 'planet', 'plus', 'premium'], selected[1])
          "#{SublimeVideo.Misc.Utils.capitalize(selected[1])} plan"
        else
          "#{SublimeVideo.Misc.Utils.capitalize(selected[1])} add-on"
      text + ' subscription billed'
    else
      switch selected[0]
        when 'ne' then 'New subscriptions billed'
        when 're' then 'Renewed subscriptions billed'
        when 'total' then 'Total subscriptions billed'

  customPluck: (selected, from = null, to = null) ->
    array = []
    from  ||= this.at(0).id
    to    ||= this.at(this.length - 1).id

    while from <= to
      trend = this.get(from)

      value = if trend?
        if selected.length > 1 # attribute is something like: ["ne", "premium"] or ["ne", "premium", "y"]
          v = trend.get(selected[0])
          _.each _.rest(selected), (e) -> if v[e]? then v = v[e] else v = 0
          this.recursiveHashSum(v)

        else if !_.isEmpty(_.values(trend.get(selected[0])))
          this.recursiveHashSum(trend.get(selected[0]) or 0)

        else if selected[0] is 'total'
          this.recursiveHashSum(trend.get('ne') or 0) + this.recursiveHashSum(trend.get('re') or 0)

        else
          v = trend.get(selected[0])
          if _.isEmpty(v) then 0 else v

      else
        0

      array.push value / 100
      from += 3600 * 24

    array
