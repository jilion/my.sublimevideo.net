class MySublimeVideo.Models.Source extends MySublimeVideo.Models.Asset
  defaults:
    src: ''
    found: true
    ratio: 9/16
    format: 'mp4'
    quality: 'base'
    dataName: ''
    dataUID: ''
    currentMimeType: ''

  setAndPreloadSrc: (src) ->
    unless src is this.get('src')
      this.set(src: src)

      if this.srcIsEmpty()
        this.reset()
      else if this.srcIsUrl()
        this.preloadSrc() if this.formatQuality() is 'mp4_base'
        this.checkMimeType()
      else
        this.set(found: false)

  preloadSrc: ->
    new SublimeVideo.Media.VideoPreloader(this.get('src'), this.setDimensions)

  checkMimeType: ->
    $.ajax
      type: "POST"
      url: "/mime-type-check"
      data: { url: this.get('src') }
      dataType: 'text'
      context: document.body
      success: (data, textStatus, jqXHR) =>
        if data is "4"
          this.set(found: false)
          this.set(currentMimeType: '')
        else
          this.set(currentMimeType: data)
          this.set(found: true)

  extension: ->
    this.get('src').slice(this.get('src').lastIndexOf('.') + 1)

  expectedMimeType: ->
    switch this.extension()
      when 'mp4', 'm4v'
        'video/mp4'
      when 'webm'
        'video/webm'
      when 'ogv', 'ogg'
        'video/ogg'
      else
        this.get('currentMimeType')

  validMimeType: ->
    this.get('currentMimeType') is "" or this.get('currentMimeType') is this.expectedMimeType()

  setDimensions: (videoSrc, dimensions) =>
    if dimensions?
      newWidth  = parseInt(dimensions['width'], 10)
      newHeight = parseInt(dimensions['height'], 10)
      newRatio  = newHeight / newWidth

      this.set(src: videoSrc)     unless videoSrc  is this.get('src')
      this.set(width: newWidth)   unless newWidth  is this.get('width')
      this.set(height: newHeight) unless newHeight is this.get('height')
      this.set(ratio: newRatio)   unless newRatio  is this.get('ratio')

    else
      this.set(width: 0)  unless this.get('width')
      this.set(height: 0) unless this.get('height')
      this.set(ratio: 0)  unless this.get('ratio')

  qualityTitle: ->
    switch this.get('quality')
      when 'base' then 'Standard Definition'
      when 'hd' then 'High Definition'
      else this.get('quality').charAt(0).toUpperCase() + this.get('quality').slice(1);

  formatQuality: ->
    "#{this.get('format')}_#{this.get('quality')}"

  needDataQualityAttribute: ->
    !_.include(['base', 'mobile'], this.get('quality'))

  reset: ->
    super()
    this.set(dataName: '')
    this.set(dataUID: '')
    this.set(keepRatio: true)
    this.set(embedWidth: null)
    this.set(embedHeight: null)
    this.set(currentMimeType: '')

class MySublimeVideo.Collections.Sources extends Backbone.Collection
  model: MySublimeVideo.Models.Source

  mp4Base: ->
    this.byFormatAndQuality(['mp4', 'base'])

  mp4Mobile: ->
    mobileSource = this.byFormatAndQuality(['mp4', 'mobile'])
    if mobileSource and mobileSource.get('src') isnt '' then mobileSource else this.mp4Base()

  hdPresent: ->
    sources = this.allByQuality('hd')
    sources.length and _.find sources, (source) -> source.get('src') isnt ''

  # Finders
  allByFormat: (format) ->
    this.select (source) -> source.get('format') is format

  allByQuality: (quality) ->
    this.select (source) -> source.get('quality') is quality

  allNonBase: ->
    this.select (source) -> source.get('quality') isnt 'base'

  allUsedNotEmpty: ->
    this.select (source) -> !source.srcIsEmpty()

  byQuality: (quality) ->
    this.find (source) -> source.get('quality') is quality

  byFormatAndQuality: (format_and_quality) ->
    this.find (source) -> source.formatQuality() is "#{format_and_quality[0]}_#{format_and_quality[1]}"

  # Return used and usable sources, sorted by MP4 first and then WebM/Ogg
  # and putting HD sources first if +startWithHd+ is true.
  sortedSources: (startWithHd) ->
    mp4Sources    = this.allByFormat('mp4')
    webMSources   = this.allByFormat('webm')
    sortedSources = []

    _.each [mp4Sources, webMSources], (family) ->
      baseSource   = _.find(family, (source) -> source.srcIsUsable() and source.get('quality') is 'base')
      hdSource     = _.find(family, (source) -> source.srcIsUsable() and source.get('quality') is 'hd')
      mobileSource = _.find(family, (source) -> source.srcIsUsable() and source.get('quality') is 'mobile')
      sources      = if startWithHd then [hdSource, baseSource] else [baseSource, hdSource]
      sortedSources.push([sources, mobileSource])

    _.compact _.flatten sortedSources

  constructParamsFromSources: (startWithHd) ->
    i = 1
    params = ""
    _.each this.sortedSources(startWithHd), (source) ->
      if source.srcIsEmptyOrUrl()
        params += "&src#{i}=" + encodeURIComponent("(#{source.get('quality')})#{source.get('src')}")
        i++

    params
