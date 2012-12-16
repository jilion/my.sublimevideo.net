#= require ./stat

class AdminSublimeVideo.Models.BillableItemsStat extends AdminSublimeVideo.Models.Stat
  defaults:
    be: 0 # beta
    tr: 0 # trial
    sb: 0 # subscribed
    sp: 0 # sponsored
    su: 0 # suspended

class AdminSublimeVideo.Collections.BillableItemsStats extends AdminSublimeVideo.Collections.Stats
  model: AdminSublimeVideo.Models.BillableItemsStat
  url: -> '/stats/billable_items.json'
  id: -> 'billable_items'
  yAxis: (selected) -> 6

  title: (selected) ->
    text = switch selected[0]
      when 'be' then 'Beta'
      when 'tr' then 'Trial'
      when 'sb' then 'Subscribed'
      when 'sp' then 'Sponsored'
      when 'su' then 'Suspended'
      when 'all' then 'All billable items'

    if selected.length > 1 # attribute is something like: ["be", "design"] or ["be", "design", "classic"]
      if selected.length > 2 # attribute is something like: ["be", "design", "classic"]
        if selected[1] is 'design'
          text += " #{SublimeVideo.Misc.Utils.capitalize(selected[2])} design"
        else
          text += " #{SublimeVideo.Misc.Utils.capitalize(selected[1])} / #{SublimeVideo.Misc.Utils.capitalize(selected[2])} add-on"
      else # design / add-on
        text += if selected[1] is 'design'
          " designs"
        else
          " #{SublimeVideo.Misc.Utils.capitalize(selected[1])} add-on"
    else
      text += ' billable items'
    text

  customPluck: (selected, from = null, to = null) ->
    array = []
    from  ||= this.at(0).id
    to    ||= this.at(this.length - 1).id

    while from <= to
      stat = this.get(from)
      value = if stat?
        if selected.length > 1 # attribute is something like: ["be", "design"] or ["be", "design", "classic"]
          v = stat.get(selected[0])
          _.each _.rest(selected), (e) -> if v[e]? then v = v[e] else v = 0
          this.recursiveHashSum(v)

        else if !_.isEmpty(_.values(stat.get(selected[0])))
          this.recursiveHashSum(stat.get(selected[0]) or 0)

        else if selected[0] is 'all'
          this.recursiveHashSum(stat.get('ne') or 0) + this.recursiveHashSum(stat.get('re') or 0)

        else
          v = stat.get(selected[0])
          if _.isEmpty(v) then 0 else v

      else
        0

      array.push value
      from += 3600 * 24

    array

