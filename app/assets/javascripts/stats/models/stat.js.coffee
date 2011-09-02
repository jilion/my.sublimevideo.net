class MSVStats.Models.Stat extends Backbone.Model
  defaults:
    t: null
    mi: null
    hi: null
    di: null
    pv: {}
    vv: {}
    md: {}
    bp: {}

  isPeriodType: (type) ->
    switch type
      when 'minutes'
        this.get('mi') != null
      when 'hours'
        this.get('hi') != null
      when 'days'
        this.get('di') != null

  time: ->
    parseInt(this.get('mi') || this.get('hi') || this.get('di'))

  date: ->
    new Date(this.time())

class MSVStats.Collections.Stats extends Backbone.Collection
  model: MSVStats.Models.Stat

  url: ->
    "/sites/#{MSVStats.sites.selectedSite().get('token')}/stats"

  vvData: ->
    this.forCurrentPeriod().reduce((memo, stat) ->
      if pv = stat.get('pv')
         memo.pv.push([stat.time(), parseInt(pv.m ? 0) + parseInt(pv.e ? 0)])  # only main & extra hostname
      if vv = stat.get('vv')
         memo.vv.push([stat.time(), parseInt(vv.m ? 0) + parseInt(vv.e ? 0)])  # only main & extra hostname
      memo
    new VVData)

  bpData: ->
    this.forCurrentPeriod().reduce((memo, stat) ->
      _.each(stat.get('bp'), (hits, bp) -> memo.set(bp, hits))
      memo
    new BPData)

  mdData: ->
    this.forCurrentPeriod().reduce((memo, stat) ->
      if md = stat.get('md')
         memo.set(md)
      memo
    new MDData)

  forCurrentPeriod: ->
    return unless MSVStats.stats
    periodStats = MSVStats.stats.reduce((memo, stat) ->
      memo.push(stat) if stat.isPeriodType(MSVStats.period.get('type'))
      memo
    [])
    return [] if _.isEmpty(periodStats)

    periodLast = MSVStats.period.get('last')
    stats = []
    switch MSVStats.period.get('type')
      when 'minutes'
        currentMinute = MSVStats.Models.Period.today()
        periodLast = parseInt(periodLast)
        while (periodLast -= 1) >= -1
          stepTime = currentMinute.date.getTime()
          periodStat = _.detect(periodStats, ((periodStat) -> periodStat.time() == stepTime))
          stats.push(periodStat || new MSVStats.Models.Stat(mi: String(stepTime)))
          currentMinute.subtract(m: 1)
        # remove current minute if null (wait for the right data)
        if _.first(stats).get('t') == null
          stats.shift()
        # remove last minute if current minute is real
        else
          stats.pop()
      when 'hours'
        currentHour = MSVStats.Models.Period.today(m: 0)
        periodLast = parseInt(periodLast)
        while (periodLast -= 1) >= 0
          stepTime = currentHour.date.getTime()
          periodStat = _.detect(periodStats, ((periodStat) -> periodStat.time() == stepTime))
          stats.push(periodStat || new MSVStats.Models.Stat(hi: String(stepTime)))
          currentHour.subtract(h: 1)
      when 'days'
        currentDay = MSVStats.Models.Period.today(h: 0)
        if periodLast == 'all'
          lastTime = _.last(periodStats).time()
          stepTime = currentDay.add(d: 1)
          while stepTime.subtract(d: 1).date.getTime() >= lastTime
            periodStat = _.detect(periodStats, ((periodStat) -> periodStat.time() == stepTime.date.getTime()))
            stats.push(periodStat || new MSVStats.Models.Stat(di: String(stepTime.date.getTime())))
        else # number
          periodLast = parseInt(periodLast)
          while (periodLast -= 1) >= 0
            stepTime = currentDay.date.getTime()
            periodStat = _.detect(periodStats, ((periodStat) -> periodStat.time() == stepTime))
            stats.push(periodStat || new MSVStats.Models.Stat(di: String(stepTime)))
            currentDay.subtract(d: 1)
    stats.reverse()


class VVData
  constructor: ->
    @pv = []
    @vv = []

  pvTotal: ->
    _.reduce(@pv, ((memo, num) -> memo + num[1]), 0)

  vvTotal: ->
    _.reduce(@vv, ((memo, num) -> memo + num[1]), 0)

class BPData
  set: (bp, hits) ->
    if _.isUndefined(this[bp])
      this[bp] = hits
    else
      this[bp] += hits

  toArray: ->
    datas = _.reduce(this, (memo, hits, bp) ->
      memo.push([BPData.bpName(bp), hits]) if hits > 0
      memo
    [])
    _.sortBy(datas, (data) -> data[1]).reverse()

  @bpName: (bp) ->
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
        else name
    ).join(' - ')

class MDData
  constructor: ->
    @m =
      'HTML5':0
      'Flash':0
    @d =
      'HTML5 - Desktop': 0
      'HTML5 - Mobile': 0
      'HTML5 - Tablet': 0
      'Flash - Desktop': 0
      'Flash - Mobile': 0
      'Flash - Tablet': 0

  set: (md) ->
    _.each(md.h, (hits, d) ->
      this.m['HTML5'] += hits
      switch d
        when 'd' then this.d['HTML5 - Desktop'] += hits
        when 'm' then this.d['HTML5 - Mobile'] += hits
        when 't' then this.d['HTML5 - Tablet'] += hits
    , this)
    _.each(md.f, (hits, d) ->
      this.m['Flash'] += hits
      switch d
        when 'd' then this.d['Flash - Desktop'] += hits
        when 'm' then this.d['Flash - Mobile'] += hits
        when 't' then this.d['Flash - Tablet'] += hits
    , this)

  toArray: (field) ->
    _.reduce(this[field], (memo, hits, key) ->
      memo.push([key, hits]) if hits > 0
      memo
    [])
