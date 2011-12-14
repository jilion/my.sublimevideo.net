class SVStats.Models.UsagesStat extends SVStats.Models.Stat
  defaults:
    pv: 0 # main + extra
    vv: 0 # main + extra
    bvv: 0 # billable video views, only days stats: main + extra + embed
    md: {}
    bp: {}

class SVStats.Collections.UsagesStats extends SVStats.Collections.Stats
  model: SVStats.Models.UsagesStat
  initialize: -> @selected = 'production'
  url: -> '/stats/usages.json'
  id: -> 'usages'
  color: -> 'rgba(255,255,0,0.5)'

  title: ->
    switch @selected
      when 'production' then 'Production (main or extra)'
      when 'embed' then 'Embed'
      when 'dev' then 'Dev'

  customPluck: ->
    array = []
    from  = this.at(0).id
    to    = this.at(this.length - 1).id

    while from <= to
      stat = this.get(from)

      value = if stat?
        if _.isArray(@selected)
          el = stat.get(_.first(@selected))
          if @selected.length > 1 # attribute is something like: ["tr_details", "premium", "y"]
            _.each _.rest(@selected), (e) -> el = el[e]
            unless _.isEmpty(_.values(el))
              el = _.reduce(_.values(el), ((memo, num) -> return memo + num), 0)

          el
        else
          switch @selected
            when 'all' then stat.get('fr') + stat.get('tr') + stat.get('pa') + stat.get('su') + stat.get('ar')
            when 'active' then stat.get('fr') + stat.get('tr') + stat.get('pa')
            when 'passive' then stat.get('su') + stat.get('ar')
            else stat.get(@selected)
      else
        0
      array.push value
      from += 3600 * 24

    array
