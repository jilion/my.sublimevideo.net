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
    # 62 0 arrays (didn't find a way to use a function to declare them, shame on me)
    vl_array: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] # main + extra
    vv_array: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] # main + extra

  initialize: ->
    @endTime = MSVStats.videos.endTime ? MSVStats.period.startTime()
    this.fetchMetaData() unless this.get('uo')?

  fetchMetaData: =>
    $.get this.metaDataUrl(), (data) =>
      this.set(data)

  metaDataUrl: =>
    "/sites/#{MSVStats.sites.selectedSite.get('token')}/video_tags/#{this.id}.json"

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

  arraysLength: ->
    this.get('vl_array').length

  vlTotal: -> this.customSum('vl')
  vvTotal: -> this.customSum('vv')
  customSum: (field) ->
    if this.get("#{field}_sum")?
      parseInt(this.get("#{field}_sum"))
    else
      _.reduce(this.get("#{field}_array").slice(0, 60), (memo, hits) ->
        memo + hits
      0)

class MSVStats.Collections.Videos extends Backbone.Collection
  model: MSVStats.Models.Video

  initialize: ->
    this.clearCollectionAttributes()

  url: ->
    "/sites/#{MSVStats.sites.selectedSite.get('token')}/stats/videos.json?#{this.urlParams()}"

  urlParams: ->
    params = [
      "period=#{MSVStats.period.get('type')}"
      "from=#{MSVStats.period.startTime() / 1000}"
      "to=#{MSVStats.period.endTime() / 1000}"
      "sort_by=#{MSVStats.topVideosView.sortBy}"
      "count=#{MSVStats.topVideosView.count}"
    ].join('&')

  # Handle custom json field (total, startTime)
  parse: (data) ->
    return [] if !data
    @total     = data.total
    @startTime = parseInt(data.from) * 1000
    @endTime   = parseInt(data.to) * 1000
    @period    = data.period
    return data.videos

  clearCollectionAttributes: ->
    @total     = null
    @startTime = null
    @endTime   = null
    @period    = null

  startDate: ->
    new Date(@startTime)

  endDate: ->
    new Date(@endTime)

  isSamePeriod: ->
    period = MSVStats.period
    if period.isDays()
      period.get('type') == @period && period.startTime() == @startTime && period.endTime() == @endTime
    else
      period.get('type') == @period

  updateSeconds: (secondTime) =>
    console.log "Video updateSeconds!: #{secondTime}"
    @startTime = MSVStats.period.startTime()
    @endTime   = secondTime
    this.addEmptyNewStats(secondTime)
    this.removeOldStats()
    this.trigger('reset', this)

  addEmptyNewStats: (endTime) ->
    for video in this.models
      console.log video.arraysLength()
      unless video.endTime == endTime
        video.endTime = endTime
        video.get('vl_array').push(0)
        video.get('vv_array').push(0)

  removeOldStats: ->
    for video in this.models
      video.get('vl_array').shift()
      video.get('vv_array').shift()

  fetchOldSeconds: =>
    MSVStats.videos.total = 1
    MSVStats.videos.period = 'seconds'

  merge: (data, options) ->
    for videoData in data
      unless (video = this.get(videoData.u))?
        this.add({id: videoData.u, n: videoData.n}, silent: true)
        video = this.get(videoData.u)

      secondTime  = parseInt(videoData.id) * 1000
      indexOffset = (secondTime - video.endTime) / 1000
      lastIndex   = video.arraysLength() - 1
      dataIndex   = lastIndex + indexOffset
      if dataIndex <= lastIndex
        video.get('vl_array')[dataIndex] += parseInt(videoData.vl) if videoData.vl?
        video.get('vv_array')[dataIndex] += parseInt(videoData.vv) if videoData.vv?
      else
        video.endTime = secondTime
        video.get('vl_array').push(videoData.vl ? 0)
        video.get('vv_array').push(videoData.vv ? 0)
