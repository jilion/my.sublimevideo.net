#= require ./trend

class AdminSublimeVideo.Models.RevenuesTrend extends AdminSublimeVideo.Models.Trend
  defaults:
    r: 0 # revenues

class AdminSublimeVideo.Collections.RevenuesTrends extends AdminSublimeVideo.Collections.Trends
  model: AdminSublimeVideo.Models.RevenuesTrend
  url: -> '/trends/revenues.json'
  id: -> 'revenues'
  chartType: (selected) -> 'column'
  yAxis: (selected) -> 0

  title: (selected) ->
    if selected.length > 1 # attribute is something like: ["r", "design", "html5"]
      text = 'Revenues from '
      if selected.length > 2 # attribute is something like: ["r", "logo", "disabled"]
        text += "#{SublimeVideo.Misc.Utils.capitalize(selected[1])} (#{SublimeVideo.Misc.Utils.capitalize(selected[2])}) add-on"
      else
        text += switch SublimeVideo.Misc.Utils.capitalize(selected[1])
                  when 'design'
                    'designs'
                  else
                    "#{SublimeVideo.Misc.Utils.capitalize(selected[1])} add-on"
      text
    else
      switch selected[0]
        when 'r' then 'Revenues from all subscriptions'

  customPluck: (selected, from = null, to = null) ->
    array = []
    from  ||= this.at(0).id
    to    ||= this.at(this.length - 1).id

    while from <= to
      trend = this.get(from)

      value = if trend?
        if selected.length > 1 # attribute is something like: ["r", "design", "html5"]
          v = trend.get(selected[0])
          _.each _.rest(selected), (e) -> if v[e]? then v = v[e] else v = 0
          this.recursiveHashSum(v)

        else if !_.isEmpty(_.values(trend.get(selected[0])))
          this.recursiveHashSum(trend.get(selected[0]) or 0)

        else
          v = trend.get(selected[0])
          if _.isEmpty(v) then 0 else v

      else
        0

      array.push value / 100
      from += 3600 * 24

    array
