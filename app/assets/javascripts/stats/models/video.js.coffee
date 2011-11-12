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
    this.fetchMetaData() unless this.metaDataPresent()

  metaDataPresent: -> this.get('uo')?

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

  arraysLength: -> this.get('vl_array').length

  vlTotal: -> this.customSum('vl')
  vvTotal: -> this.customSum('vv')
  customSum: (field) ->
    if this.get("#{field}_sum")?
      parseInt(this.get("#{field}_sum"))
    else
      _.reduce(this.get("#{field}_array").slice(0, 60), (memo, hits) ->
        memo + hits
      0)

  total: (field) ->
    switch field
      when 'vl' then this.vlTotal()
      when 'vv' then this.vvTotal()

  isEmpty: ->
    _.all(this.get('vl_array'), ((hit) -> hit == 0)) && _.all(this.get('vv_array'), ((hit) -> hit == 0))

  isShowable: -> this.vlTotal() > 0 || this.vvTotal() > 0

class MSVStats.Collections.Videos extends Backbone.Collection
  model: MSVStats.Models.Video

  initialize: ->
    this.clearCollectionAttributes()
    @limit  = 5
    @sortBy = 'vv'

  url: ->
    "/sites/#{MSVStats.sites.selectedSite.get('token')}/stats/videos.json?#{this.urlParams()}"

  urlParams: ->
    params = [
      "period=#{MSVStats.period.get('type')}"
      "from=#{MSVStats.period.startTime() / 1000}"
      "to=#{MSVStats.period.endTime() / 1000}"
      "sort_by=#{@sortBy}"
      "limit=#{@limit}"
    ].join('&')

  # Handle custom json field (total, startTime)
  parse: (data) ->
    return [] if !data
    @total     = parseInt(data.total)
    @limit     = parseInt(data.limit)
    @startTime = parseInt(data.from) * 1000
    @endTime   = parseInt(data.to) * 1000
    @period    = data.period
    @sortBy    = data.sort_by
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

  change: (options = {}) ->
    @sortBy = options.sortBy if options.sortBy?
    @limit  = options.limit if options.limit?
    if @period == 'seconds'
      this.trigger('reset', this)
    else
      this.fetch()

  showableModels: ->
    if @period == 'seconds'
      iterator = switch @sortBy
        when 'vl' then ((video) -> video.vlTotal() )
        when 'vv' then ((video) -> video.vvTotal() )
      models = _.sortBy(@models, iterator).reverse()
      models.slice(0, @limit)
    else
      this.models

  isSamePeriod: ->
    period = MSVStats.period
    if period.isDays()
      period.get('type') == @period && period.startTime() == @startTime && period.endTime() == @endTime
    else
      period.get('type') == @period

  isShowable: ->
    _.any(this.showableModels(), ((video) -> video.isShowable()))

  updateSeconds: (secondTime) =>
    @startTime = MSVStats.period.startTime()
    @endTime   = secondTime
    this.addEmptyNewStats(secondTime)
    this.removeOldStats()
    this.removeEmptyVideos()
    this.trigger('reset', this)

  addEmptyNewStats: (endTime) ->
    for video in this.models
      unless video.endTime == endTime
        video.endTime = endTime
        vlArray = _.clone(video.get('vl_array'))
        vlArray.push(0)
        vvArray = _.clone(video.get('vv_array'))
        vvArray.push(0)
        video.set({ vl_array: vlArray, vv_array: vvArray }, silent: true)

  removeOldStats: ->
    for video in this.models
      vlArray = _.clone(video.get('vl_array'))
      vlArray.shift()
      vvArray = _.clone(video.get('vv_array'))
      vvArray.shift()
      video.set({ vl_array: vlArray, vv_array: vvArray }, silent: true)

  removeEmptyVideos: ->
    for video in this.models
      this.remove(video, silent: true) if video.isEmpty()

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

      vlArray = _.clone(video.get('vl_array'))
      vvArray = _.clone(video.get('vv_array'))
      if dataIndex <= lastIndex
        vlArray[dataIndex] += parseInt(videoData.vl) if videoData.vl?
        vvArray[dataIndex] += parseInt(videoData.vv) if videoData.vv?
      else
        video.endTime = secondTime
        vlArray.push(videoData.vl ? 0)
        vvArray.push(videoData.vv ? 0)
      video.set({ vl_array: vlArray, vv_array: vvArray }, silent: true)
