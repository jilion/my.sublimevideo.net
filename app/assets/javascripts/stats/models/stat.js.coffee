class MSVStats.Models.Stat extends Backbone.Model
  defaults:
    t: null
    m: null
    h: null
    d: null
    pv: {}
    vv: {}
    md: {}
    bp: {}

  isPeriodType: (type) ->
    switch type
      when 'minute'
        this.get('m') != null
      when 'hour'
        this.get('h') != null
      when 'day'
        this.get('d') != null

  date: ->
    dateString = this.get('m') || this.get('h') || this.get('d')
    new Date(dateString)

class MSVStats.Collections.Stats extends Backbone.Collection
  model: MSVStats.Models.Stat

  url: ->
    "/sites/#{MSVStats.sites.selectedSite().get('token')}/stats"

  vvData: ->
    this.forCurrentPeriod().reduce((memo, stat) ->
      if pv = stat.get('pv')
         memo.pv.push(parseInt(pv.m ? 0) + parseInt(pv.e ? 0))  # only main & extra hostname
      if vv = stat.get('vv')
         memo.vv.push(parseInt(vv.m ? 0) + parseInt(vv.e ? 0))  # only main & extra hostname
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
    stats = MSVStats.stats.reduce((memo, stat) ->
      memo.push(stat) if stat.isPeriodType(MSVStats.period.get('type'))
      memo
    [])

    periodLast = MSVStats.period.get('last')
    if periodLast == 'all'
      stats = _.sortBy(stats, (stat) -> stat.date().getTime())
    else # number
      stats = _.sortBy(stats, (stat) -> stat.date().getTime()).reverse()
      _.first(stats, periodLast).reverse()

class VVData
  constructor: ->
    @pv = []
    @vv = []
  
  pvTotal: ->
    _.reduce(@pv, ((memo, num) -> memo + num), 0)
  
  vvTotal: ->
    _.reduce(@vv, ((memo, num) -> memo + num), 0)

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
