class SVStats.Models.SitesStat extends Backbone.Model
  defaults:
    fr: 0 # free
    tr: 0 # paying
    pa: 0 # paying
    tr_details: {} # trial details
    pa_details: {} # paying details
    su: 0 # suspended
    ar: 0 # archived

  time: ->
    parseInt(this.id) * 1000

  date: ->
    new Date(this.time())

class SVStats.Collections.SitesStats extends Backbone.Collection
  model: SVStats.Models.SitesStat

  initialize: ->
    @selected = 'active'

  url: -> "/stats/sites.json"

  chartType: -> 'line'

  id: -> 'sites'

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
          if @selected.length == 3 # attribute is something like: ["tr_details", "premium", "y"]
            text += if @selected[2] == "y" then "yearly" else "monthly"
          text += " #{@selected[1]} plan"
          text
        else
          'Sites'

  startTime: ->
    _.min(@models, (m) -> m.id).time()

  endTime: ->
    _.max(@models, (m) -> m.id).time()

  customPluck: ->
    array = []
    from  = this.at(0).id
    to    = this.at(this.length - 1).id

    while from <= to
      stat = this.get(from)

      value = if _.isArray(@selected)
        el = stat.get(_.first(@selected))
        if @selected.length > 1 # attribute is something like: ["tr_details", "premium", "y"]
          _.each _.rest(@selected), (e) -> el = el[e]
          unless _.isEmpty(_.values(el))
            el = _.reduce(_.values(el), ((memo, num) -> return memo + num), 0)

        el
      else
        value = if stat?
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
