class SVStats.Models.SitesStat extends SVStats.Models.Stat
  defaults:
    fr: 0 # free
    tr: {} # trial
    pa: {} # paying
    su: 0 # suspended
    ar: 0 # archived

class SVStats.Collections.SitesStats extends SVStats.Collections.Stats
  model: SVStats.Models.SitesStat
  url: -> '/stats/sites.json'
  id: -> 'sites'
  color: -> 'rgba(255,0,0,0.5)'

  title: ->
    switch @selected
      when 'fr' then 'Free sites'
      when 'tr' then 'Sites in trial'
      when 'pa' then 'Paying sites'
      when 'su' then 'Suspended sites'
      when 'ar' then 'Archived sites'
      when 'active' then 'Active sites (free, in trial or paying)'
      when 'passive' then 'Passive sites (suspended or archived)'
      else
        if _.isArray(@selected)
          text = "Sites with the "
          if @selected.length == 3 # attribute is something like: ["tr", "premium", "y"]
            text += if @selected[2] == "y" then "yearly" else "monthly"
          text += " #{@selected[1]} plan"
          text
        else
          'Sites'

  customPluck: ->
    array = []
    from  = this.at(0).id
    to    = this.at(this.length - 1).id

    while from <= to
      stat = this.get(from)

      value = if stat?
        if _.isArray(@selected)
          value = stat.get(_.first(@selected))
          if @selected.length > 1 # attribute is something like: ["tr", "premium", "y"]
            _.each _.rest(@selected), (e) -> value = value[e]
            value = this.recursiveHashSum(value)
          value
        else if !_.isEmpty(_.values(stat.get(@selected)))
          this.recursiveHashSum(stat.get(@selected))
        else
          switch @selected
            when 'all' then stat.get('fr') + this.recursiveHashSum(stat.get('tr')) + this.recursiveHashSum(stat.get('pa')) + stat.get('su') + stat.get('ar')
            when 'active' then stat.get('fr') + this.recursiveHashSum(stat.get('tr')) + this.recursiveHashSum(stat.get('pa'))
            when 'passive' then stat.get('su') + stat.get('ar')
            else stat.get(@selected)
      else
        0
      array.push value
      from += 3600 * 24

    array

  recursiveHashSum: (hash) ->
    sum = 0
    if _.isNumber(hash)
      sum = hash
    else
      _.each _.values(hash), (value) =>
        sum += this.recursiveHashSum(value)

    sum
