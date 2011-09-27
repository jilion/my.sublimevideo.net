class MSVStats.Models.Stat extends Backbone.Model
  defaults:
    t:  null
    pv: 0
    vv: 0
    md: {}
    bp: {}

  time: ->
    parseInt(this.get('t')) * 1000

  date: ->
    new Date(this.time())

class MSVStats.Collections.Stats extends Backbone.Collection
  model: MSVStats.Models.Stat

  pvTotal: ->
    this.sum('pv')

  vvTotal:->
    this.sum('vv')

  sum: (attribute) ->
    _.reduce @models, ((memo, stat) -> memo + stat.get(attribute)), 0

  bpData: ->
    this.customReduce((memo, stat) ->
      _.each(stat.get('bp'), (hits, bp) -> memo.set(bp, hits))
      memo
    new BPData)

  mdData: ->
    this.customReduce((memo, stat) ->
      memo.set(md) if md = stat.get('md')
      memo
    new MDData)

  customReduce: (iterator, context) ->
    if MSVStats.period.isFullRange()
      _.reduce @models, ((memo, stat) -> iterator(memo, stat)), context
    else
      datesRange = MSVStats.period.datesRange()
      _.reduce(@models, (memo, stat) ->
        if stat.time() >= datesRange[0] && stat.time() <= datesRange[1]
          iterator(memo, stat)
        else
          memo
      context)
      
  @allPresent: ->
    !MSVStats.statsSeconds.isEmpty() && !MSVStats.statsMinutes.isEmpty() && !MSVStats.statsHours.isEmpty() && !MSVStats.statsDays.isEmpty()

class MSVStats.Collections.StatsSeconds extends MSVStats.Collections.Stats
  url: ->
    "/sites/#{MSVStats.sites.selectedSite().get('token')}/stats?period=seconds"

  periodType: -> 'seconds'

class MSVStats.Collections.StatsMinutes extends MSVStats.Collections.Stats
  url: ->
    "/sites/#{MSVStats.sites.selectedSite().get('token')}/stats"

  periodType: -> 'minutes'

class MSVStats.Collections.StatsHours extends MSVStats.Collections.Stats
  url: ->
    "/sites/#{MSVStats.sites.selectedSite().get('token')}/stats?period=hours"

  periodType: -> 'hours'

class MSVStats.Collections.StatsDays extends MSVStats.Collections.Stats
  url: ->
    "/sites/#{MSVStats.sites.selectedSite().get('token')}/stats?period=days"

  periodType: -> 'days'

  pvTotal: ->
    this.customSum('pv')

  vvTotal: (datesRange) ->
    this.customSum('vv', datesRange)

  customSum: (attribute, datesRange = MSVStats.period.datesRange()) ->
    _.reduce(@models, (memo, stat) ->
      if stat.time() >= datesRange[0] && stat.time() <= datesRange[1] then memo + stat.get(attribute) else memo
    0)

  customPluck: (attribute, firstIndex) ->
    stats = @models.slice(firstIndex)
    _.map stats, ((stat) -> stat.get('vv'))

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
      'Tablet': 0
    @df =
      'Desktop': 0
      'Mobile': 0
      'Tablet': 0

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
        when 't' then this.dh['Tablet']  += hits
    , this)
    _.each(md.f, (hits, df) ->
      @mf     += hits
      @total  += hits
      switch df
        when 'd' then this.df['Desktop'] += hits
        when 'm' then this.df['Mobile']  += hits
        when 't' then this.df['Tablet']  += hits
    , this)

  toArray: (field) ->
    datas = _.reduce(this[field], (memo, hits, key) ->
      memo.push([key, hits]) if hits > 0
      memo
    [])
    _.sortBy(datas, (data) -> data[1]).reverse()

  isEmpty: ->
    @total == 0
