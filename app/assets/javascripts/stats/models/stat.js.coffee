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

  bpData: ->
    this.forCurrentPeriod().reduce((memo, stat) ->
      _.each(stat.get('bp'), (hits, bp) -> memo.set(bp, hits))
      memo
    new BPData)

  forCurrentPeriod: ->
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
  