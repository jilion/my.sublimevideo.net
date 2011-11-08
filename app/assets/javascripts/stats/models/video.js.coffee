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
    vl_sum: 0 # main + extra
    vv_sum: 0 # main + extra
    vv_array: [] # main + extra

  currentSources: ->
    sources = []
    for s in this.get('cs')
      if this.get('s')[s]?
        sources.push this.get('s')[s]
    sources

class MSVStats.Collections.Videos extends Backbone.Collection
  url: ->
    "/sites/#{MSVStats.sites.selectedSite.get('token')}/stats/videos.json?period=#{MSVStats.period.get('type')}&from=#{MSVStats.period.startTime() / 1000}&to=#{MSVStats.period.endTime() / 1000}"

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