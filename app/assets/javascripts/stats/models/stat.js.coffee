class MSVStats.Models.Stat extends Backbone.Model
  # id = Stat time (day, hour, minute or second)
  defaults:
    pv: 0 # main + extra
    vv: 0 # main + extra
    bvv: 0 # billable video views, only days stats: main + extra + embed
    md: {}
    bp: {}

  time: ->
    parseInt(this.id) * 1000

  date: ->
    new Date(this.time())

class MSVStats.Collections.Stats extends Backbone.Collection
  model: MSVStats.Models.Stat

  chartType: -> 'areaspline'

  pvTotal: (startIndex, endIndex) ->
    this.customSum('pv', startIndex, endIndex)

  vvTotal: (startIndex, endIndex) ->
    this.customSum('vv', startIndex, endIndex)

  customSum: (attribute, startIndex, endIndex) ->
    if startIndex? && endIndex?
      datesRange = this.datesRange(startIndex, endIndex)
      _.reduce(@models, (memo, stat) ->
        if stat.time() >= datesRange[0] && stat.time() <= datesRange[1] then memo + stat.get(attribute) else memo
      0)
    else
      _.reduce @models, ((memo, stat) -> memo + stat.get(attribute)), 0

  customPluck: (attribute, startIndex, endIndex) ->
    if startIndex? && endIndex?
      datesRange = this.datesRange(startIndex, endIndex)
    this.customReduce((memo, stat) ->
      memo.push(stat.get(attribute))
      memo
    [], datesRange)

  isUnactive: ->
    this.pvTotal(0, -1) == 0 && this.vvTotal(0, -1) == 0

  bpData: ->
    unless MSVStats.period.isFullRange()
      datesRange = MSVStats.period.datesRange()
    this.customReduce((memo, stat) ->
      _.each(stat.get('bp'), (hits, bp) -> memo.set(bp, hits))
      memo
    new BPData, datesRange)

  mdData: ->
    unless MSVStats.period.isFullRange()
      datesRange = MSVStats.period.datesRange()
    this.customReduce((memo, stat) ->
      memo.set(md) if md = stat.get('md')
      memo
    new MDData, datesRange)

  customReduce: (iterator, context, datesRange) ->
    if datesRange?
      _.reduce(@models, (memo, stat) ->
        if stat.time() >= datesRange[0] && stat.time() <= datesRange[1]
          iterator(memo, stat)
        else
          memo
      context)
    else
      _.reduce @models, ((memo, stat) -> iterator(memo, stat)), context

  merge: (data, options) ->
    if (stat = this.get(data.id))?
      attributes = {}
      attributes.pv = stat.get('pv') + data.pv if data.pv?
      attributes.vv = stat.get('vv') + data.vv if data.vv?
      if data.md?
        attributes.md = _.clone(stat.get('md'))
        if data.md.f?
          attributes.md.f = {} if _.isUndefined(attributes.md.f)
          _.each data.md.f, (hits, d) ->
            if _.isUndefined(attributes.md.f[d])
              attributes.md.f[d] = hits
            else
              attributes.md.f[d] += hits
        if data.md.h?
          attributes.md.h = {} if _.isUndefined(attributes.md.h)
          _.each data.md.h, (hits, d) ->
            if _.isUndefined(attributes.md.h[d])
              attributes.md.h[d] = hits
            else
              attributes.md.h[d] += hits
      if data.bp?
        attributes.bp = _.clone(stat.get('bp'))
        _.each data.bp, (hits, bp) ->
          if _.isUndefined(attributes.bp[bp])
            attributes.bp[bp] = hits
          else
            attributes.bp[bp] += hits
      stat.set attributes, options
    else
      this.add data, options

  datesRange: (startIndex, endIndex) ->
    if this.isEmpty()
      [null, null]
    else
      startStat = this.at(this.normalizeStatsIndex(startIndex))
      endStat   = this.at(this.normalizeStatsIndex(endIndex))
      if startStat? && endStat?
        [startStat.time(), endStat.time()]
      else
        [null, null]

  normalizeStatsIndex: (index) ->
    if index < 0 then this.length + index else index

  @allPresent: ->
    if MSVStats.sites.selectedSite.inFreePlan()
      !MSVStats.statsMinutes.isEmpty() && !MSVStats.statsHours.isEmpty()
    else
      !MSVStats.statsMinutes.isEmpty() && !MSVStats.statsHours.isEmpty() && !MSVStats.statsDays.isEmpty()

class MSVStats.Collections.StatsSeconds extends MSVStats.Collections.Stats
  url: ->
    "/sites/#{MSVStats.sites.selectedSite.get('token')}/stats.json?period=seconds"

  # chartType: -> 'column'
  chartType: -> 'areaspline'
  periodType: -> 'seconds'

  updateSeconds: (secondTime) =>
    currentStatId = secondTime / 1000
    unless this.get(currentStatId)?
      this.add({ id: currentStatId }, silent: true)

    if this.length > 62
      this.removeOldStats(62)

  fetchOldSeconds: =>
    $.get this.url(), (data) =>
      for stat in data.reverse()
        if (statSecond = MSVStats.statsSeconds.get(stat.id))?
          statSecond.set(stat, silent: true)
        else
          MSVStats.statsSeconds.add(stat, silent: true, at: 0)
      this.removeOldStats(62)

  removeOldStats: (count) ->
    while this.length > count
      this.remove(this.first(), silent: true)
      this.trigger('change', this)

  isShowable: -> this.length >= 62

  lastStatTime: ->
    last = this.last()
    if last? then last.time() else 0

class MSVStats.Collections.StatsMinutes extends MSVStats.Collections.Stats
  url: ->
    "/sites/#{MSVStats.sites.selectedSite.get('token')}/stats"

  periodType: -> 'minutes'

class MSVStats.Collections.StatsHours extends MSVStats.Collections.Stats
  url: ->
    "/sites/#{MSVStats.sites.selectedSite.get('token')}/stats?period=hours"

  periodType: -> 'hours'

class MSVStats.Collections.StatsDays extends MSVStats.Collections.Stats
  url: ->
    "/sites/#{MSVStats.sites.selectedSite.get('token')}/stats?period=days"

  periodType: -> 'days'

class BPData
  constructor: ->
    @bp    = {}
    @total = 0

  set: (bp, hits) ->
    if _.isUndefined(@bp[bp])
      @bp[bp] = hits
    else
      @bp[bp] += hits
    @total += hits

  percentage: (hits) ->
    Highcharts.numberFormat (hits / @total * 100), 2

  cssClass: (bp) ->
    bp = bp.split('-')
    "b_#{bp[0]} p_#{bp[1]}"

  toArray: ->
    datas = _.reduce(@bp, (memo, hits, bp) ->
      memo.push([bp, hits]) if hits > 0
      memo
    [])
    _.sortBy(datas, (data) -> data[1]).reverse()

  isEmpty: ->
    @total == 0

  bpName: (bp) ->
    bp.split('-').map( (name) ->
      switch name
        when 'fir' then 'Firefox'
        when 'chr' then 'Chrome'
        when 'iex' then 'IE'
        when 'saf' then 'Safari'
        when 'and' then 'Android'
        when 'rim' then 'BlackBerry'
        when 'weo' then 'webOS'
        when 'ope' then 'Opera'
        when 'win' then 'Windows'
        when 'osx' then 'Macintosh'
        when 'ipa' then 'iPad'
        when 'iph' then 'iPhone'
        when 'ipo' then 'iPod'
        when 'lin' then 'Linux'
        when 'wip' then 'Windows Phone'
        when 'oth' then 'Other'
        when 'otm' then 'Other (Mobile)'
        when 'otd' then 'Other (Desktop)'
        else name
    ).join(' - ')

class MDData
  constructor: ->
    # Media
    @mh = 0
    @mf = 0
    # Devise
    @dh =
      'Desktop': 0
      'Mobile': 0
    @df =
      'Desktop': 0
      'Mobile': 0

    @total = 0

  percentage: (hits, total = this.total) ->
    Highcharts.numberFormat (hits / total * 100), 2

  set: (md) ->
    _.each(md.h, (hits, dh) ->
      @mh     += hits
      @total  += hits
      switch dh
        when 'd' then this.dh['Desktop'] += hits
        when 'm' then this.dh['Mobile']  += hits
        when 't' then this.dh['Mobile']  += hits
    , this)
    _.each(md.f, (hits, df) ->
      @mf     += hits
      @total  += hits
      switch df
        when 'd' then this.df['Desktop'] += hits
        when 'm' then this.df['Mobile']  += hits
        when 't' then this.df['Mobile']  += hits
    , this)

  toArray: (field) ->
    datas = _.reduce(this[field], (memo, hits, key) ->
      memo.push([key, hits]) if hits > 0
      memo
    [])
    _.sortBy(datas, (data) -> data[1]).reverse()

  isEmpty: ->
    @total == 0
