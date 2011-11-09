class MSVStats.Models.Video extends Backbone.Model
  # id = video uid
  defaults:
    uo: null
    n: null
    no: null
    p: null
    z: null
    cs: []
    s: {}
    vl_sum: null # main + extra
    vv_sum: null # main + extra
    vl_array: [] # main + extra
    vv_array: [] # main + extra

  currentSources: ->
    sources = []
    for s in this.get('cs')
      if this.get('s')[s]?
        sources.push this.get('s')[s]
    sources

  width: ->
    if (z = this.get('z'))?
      parseInt(z.split('x')[0])
    else
      480

  height: ->
    if (z = this.get('z'))?
      parseInt(z.split('x')[1])
    else
      360

  vlTotal: -> this.customSum('vl')
  vvTotal: -> this.customSum('vv')
  customSum: (field) ->
    if this.get("#{field}_sum")?
      parseInt(this.get("#{field}_sum"))
    else
      total = 0
      _.each this.get("#{field}_array"), (num, index) ->
        if MSVStats.period.startIndex() <= index <= MSVStats.period.endIndex()
          total += num
      total



class MSVStats.Collections.Videos extends Backbone.Collection
  model: MSVStats.Models.Video

  url: ->
    "/sites/#{MSVStats.sites.selectedSite.get('token')}/stats/videos.json?#{this.urlParams()}"

  # Handle custom json field (total, startTime)
  parse: (data) ->
    if !data
      @total  = 0
      @from   = null
      @to     = null
      @period = null
      return []

    @total     = data.total
    @startTime = parseInt(data.from) * 1000
    @endTime   = parseInt(data.to) * 1000
    @period    = data.period
    return data.videos

  startDate: ->
    new Date(@startTime)

  endDate: ->
    new Date(@endTime)

  isSamePeriod: ->
    period = MSVStats.period
    if period.get('type') == 'days'
      period.get('type') == @period && period.startTime() == @startTime && period.endTime() == @endTime
    else
      period.get('type') == @period

  urlParams: ->
    params = [
      "period=#{MSVStats.period.get('type')}"
      "from=#{MSVStats.period.startTime() / 1000}"
      "to=#{MSVStats.period.endTime() / 1000}"
      "sort_by=#{MSVStats.topVideosView.sortBy}"
      "count=#{MSVStats.topVideosView.count}"
    ].join('&')
