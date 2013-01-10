#= require ./stat

class AdminSublimeVideo.Models.TailorMadePlayerRequestsStat extends AdminSublimeVideo.Models.Stat
  defaults:
    n: {}

class AdminSublimeVideo.Collections.TailorMadePlayerRequestsStats extends AdminSublimeVideo.Collections.Stats
  model: AdminSublimeVideo.Models.TailorMadePlayerRequestsStat
  url: -> '/stats/tailor_made_player_requests.json'
  id: -> 'tailor_made_player_requests'
  yAxis: (selected) -> 2

  title: (selected) ->
    if selected.length > 1 # attribute is something like: ["n", "agency"]
      "Tailor-made player requests with topic: #{SublimeVideo.Misc.Utils.capitalize(selected[1])}"
    else
      switch selected[0]
        when 'all' then 'All tailor-made player requests'

  customPluck: (selected, from = null, to = null) ->
    array = []
    from  ||= this.at(0).id
    to    ||= this.at(this.length - 1).id

    while from <= to
      stat = this.get(from)

      value = if stat?
        if stat.get('n')[selected[0]] then stat.get('n')[selected[0]] else 0
      else
        0

      array.push value
      from += 3600 * 24

    console.log array
    array
