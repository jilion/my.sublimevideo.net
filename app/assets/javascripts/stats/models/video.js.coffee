class MSVStats.Models.Video extends Backbone.Model
  # id = video uid
  defaults:
    uid_origin: null
    name: null
    name_origin: null
    poster_url: null
    size: null
    current_sources: []
    sources: {}
    sources_id: null
    sources_origin: null
    vl_sum: null # main + extra
    vv_sum: null # main + extra
    vl_array: []
    vv_array: []
    vl_hash: {}
    vv_hash: {}

  initialize: ->
    @addTime = MSVStats.period.endTime() + (2 * 1000)
    this.fetchData() unless this.dataPresent()

  dataPresent: -> this.get('uid_origin')?

  fetchData: =>
    $.get this.dataUrl(), (data) =>
      this.set(data, silent: true) if data?

  dataUrl: =>
    "/sites/#{MSVStats.site.get('token')}/video_tags/#{this.id}.json"

  currentSources: ->
    sources = []
    for current_source in this.get('current_sources')
      if this.get('sources')[current_source]?
        sources.push this.get('sources')[current_source]
    sources

  width: ->
    if (size = this.get('size'))?
      parseInt(size.split('x')[0])
    else
      480

  height: ->
    if (size = this.get('size'))?
      parseInt(size.split('x')[1])
    else
      360

  isSecond: -> !this.get("vl_sum")?

  isUidGetFromSource: -> this.get('uid_origin') == 'source'
  isNameGetFromSource: -> this.get('name_origin') == 'source'
  isYouTubeVideo: -> this.get('sources_origin') == 'youtube'

  youtubeId: ->
    if this.isYouTubeVideo()
      this.get('sources_id')

  sslPosterUrl: ->
    if this.get('poster_url').match(/^https/)
      this.get('poster_url')
    else
      "https://data.sublimevideo.net/proxy?u=#{encodeURIComponent(this.get('poster_url'))}"

  name: (length = null) ->
    if this.get('name')?
      if length? && this.get('name').length > length
        this.get('name').substring(0, length) + '...'
      else
        this.get('name')
    else if this.isYouTubeVideo()
      "Youtube: ##{this.youtubeId().toUpperCase()}"
    else
      '–'

  vlTotal: -> this.customSum('vl')
  vvTotal: -> this.customSum('vv')
  customSum: (field) ->
    if this.isSecond()
      _.reduce(this.get("#{field}_hash"), (memo, hits, time) ->
        if (MSVStats.period.startTime() / 1000) <= time <= (MSVStats.period.endTime() / 1000)
          memo + hits
        else
          memo
      0)
    else
      parseInt(this.get("#{field}_sum"))

  vvArray: ->
    if this.isSecond()
      hash  = this.get('vv_hash')
      array = []
      from  = MSVStats.period.startTime() / 1000
      to    = MSVStats.period.endTime() / 1000
      while from <= to
        array.push(hash[from] ? 0)
        from += 1
      array
    else
      this.get('vv_array')

  total: (field) ->
    switch field
      when 'vl' then this.vlTotal()
      when 'vv' then this.vvTotal()

  isEmpty: ->
    if this.isSecond()
      _.isEmpty(this.get('vl_hash')) && _.isEmpty(this.get('vv_hash'))
    else
      _.all(this.get('vl_array'), ((hit) -> hit == 0)) && _.all(this.get('vv_array'), ((hit) -> hit == 0))

  isShowable: -> this.vlTotal() > 0 || this.vvTotal() > 0

class MSVStats.Collections.Videos extends Backbone.Collection
  model: MSVStats.Models.Video

  initialize: ->
    this.clearCollectionAttributes()
    @limit  = 5
    @sortBy = 'vv'

  url: ->
    "/sites/#{MSVStats.site.get('token')}/stats/videos.json?#{this.urlParams()}"

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
    return [] if !data || data.period != MSVStats.period.get('type')
    @total     = parseInt(data.total)
    @limit     = parseInt(data.limit)
    @period    = data.period
    @sortBy    = data.sort_by
    return data.videos

  clearCollectionAttributes: ->
    @total     = null
    @period    = null

  change: (options = {}) ->
    @sortBy = options.sortBy if options.sortBy?
    @limit  = options.limit if options.limit?
    if @period == 'seconds'
      this.trigger('reset', this)
    else
      this.fetch()

  customModels: ->
    if @period == 'seconds'
      iterator = switch @sortBy
        when 'vl' then ((video) -> video.vlTotal() )
        when 'vv' then ((video) -> video.vvTotal() )
      models = _.sortBy(@models, iterator).reverse()
      models.slice(0, @limit)
    else
      this.models

  isReady: ->
    @total? && @period == MSVStats.period.get('type')

  isShowable: (models = this.customModels()) ->
    _.any(models, ((video) -> video.isShowable()))

  updateSeconds: (secondTime) =>
    this.removeOldStats()
    this.removeEmptyVideos(secondTime)
    @total = this.models.length
    this.trigger('reset', this)

  removeOldStats: ->
    from = MSVStats.period.startTime() / 1000
    for video in this.models
      vlHash = _.clone(video.get('vl_hash'))
      vvHash = _.clone(video.get('vv_hash'))
      _.each vlHash, (hits, time) ->
        delete vlHash[time] if time < from
      _.each vvHash, (hits, time) ->
        delete vvHash[time] if time < from
      video.set({ vl_hash: vlHash, vv_hash: vvHash }, silent: true)

  removeEmptyVideos: (secondTime) ->
    for video in _.clone(this.models)
      if (secondTime - video.addTime) > 10000 && video.isEmpty()
        this.remove(video, silent: true)

  customFetch: ->
    this.clearCollectionAttributes()
    this.reset()
    if MSVStats.period.stats().isUnactive()
      # no need to fetch any data...
      @period = MSVStats.period.get('type')
      @total  = 0
    else
      if MSVStats.period.isSeconds()
        setTimeout this.fetchOldSeconds, 2000
      else
        this.fetch()

  fetchOldSeconds: =>
    $.get this.url(), (data) =>
      for videoData in data.videos
        oldVlHash = videoData.vl_hash
        delete videoData.vl_hash
        oldVvHash = videoData.vv_hash
        delete videoData.vv_hash

        video = this.getOrAdd(videoData.id, videoData)

        vlHash = _.extend(_.clone(video.get('vl_hash')), oldVlHash)
        vvHash = _.extend(_.clone(video.get('vv_hash')), oldVvHash)

        video.set({ vl_hash: vlHash, vv_hash: vvHash }, silent: true)
      @period = 'seconds'

  merge: (data, options) ->
    for videoData in data
      video  = this.getOrAdd(videoData.u, { id: videoData.u, n: videoData.n })
      second = parseInt(videoData.id)

      vlHash = _.clone(video.get('vl_hash'))
      vvHash = _.clone(video.get('vv_hash'))
      if videoData.vl?
        vlHash[second] = if vlHash[second]? then vlHash[second] + parseInt(videoData.vl) else parseInt(videoData.vl)
      if videoData.vv?
        vvHash[second] = if vvHash[second]? then vvHash[second] + parseInt(videoData.vv) else parseInt(videoData.vv)

      video.set({ vl_hash: vlHash, vv_hash: vvHash }, silent: true)

  getOrAdd: (id, attributes) ->
    if (video = this.get(id))?
      video.set(n: attributes.n, silent: true) if attributes.n?
    else
      this.add(attributes, silent: true)
      video = this.get(id)
    video
