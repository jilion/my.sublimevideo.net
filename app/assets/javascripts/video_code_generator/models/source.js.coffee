class MSVVideoCodeGenerator.Models.Source extends MSVVideoCodeGenerator.Models.Asset
  defaults:
    src: ""
    format: "mp4"
    quality: "base"
    dataName: ""
    dataUID: ""
    optional: false
    isUsed: true
    keepRatio: true
    embedWidth: null
    embedHeight: null
    ratio: 9/16
    found: true
    currentMimeType: ""

  setAndPreloadSrc: (src) ->
    unless src is this.get('src')
      this.set(src: src)

      if this.srcIsEmpty()
        this.set(found: true)
      else if this.srcIsUrl()
        this.preloadSrc() if this.formatQuality() is 'mp4_base'
        this.checkMimeType()
      else
        this.set(found: false)

      this.setDefaultDataUID() unless this.get('dataUID')
      this.setDefaultDataName() unless this.get('dataName')

  setKeepRatio: (keepRatio) ->
    this.set(keepRatio: keepRatio)
    this.setEmbedHeightWithRatio() if this.get('keepRatio')

  setDefaultDataUID: ->
    this.set(dataUID: crc32(this.get('src')))

  setDefaultDataName: ->
    name = this.get('src').slice(this.get('src').lastIndexOf('/') + 1, this.get('src').lastIndexOf('.'))
    this.set(dataName: name.titleize())

  preloadSrc: ->
    new SublimeVideo.VideoPreloader(this.get('src'), this.setDimensions)

  checkMimeType: ->
    $.ajax
      type: "POST"
      url: "/video-code-generator/mime-type-check"
      data: { url: this.get('src') }
      dataType: 'text'
      context: document.body
      success: (data, textStatus, jqXHR) =>
        if data is "4"
          this.set(found: false)
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
        'video/ogv'
      else
        this.get('currentMimeType')

  validMimeType: ->
    this.get('currentMimeType') is "" or this.get('currentMimeType') is this.expectedMimeType()

  setDimensions: (videoSrc, dimensions) =>
    if dimensions?
      newWidth  = parseInt(dimensions['width'])
      newHeight = parseInt(dimensions['height'])
      newRatio  = newHeight / newWidth

      this.set(src: videoSrc)     unless videoSrc  is this.get('src')
      this.set(width: newWidth)   unless newWidth  is this.get('width')
      this.set(height: newHeight) unless newHeight is this.get('height')
      this.set(ratio: newRatio)   unless newRatio  is this.get('ratio')

    else
      this.set(width: 0)  unless this.get('width')
      this.set(height: 0) unless this.get('height')
      this.set(ratio: 0)  unless this.get('ratio')

    this.setEmbedWidth(_.min([this.get('width'), 852]))

  setEmbedWidth: (newEmbedWidth) ->
    newEmbedWidth = parseInt(newEmbedWidth)
    newEmbedWidth = 200 if _.isNaN(newEmbedWidth) or newEmbedWidth < 200
    newEmbedWidth = 880 if newEmbedWidth > 880

    this.set(embedWidth: newEmbedWidth)
    this.setEmbedHeightWithRatio() if this.get('keepRatio')
    this.trigger('change:embedWidth')

  setEmbedHeightWithRatio: ->
    this.set(embedHeight: parseInt(this.get('embedWidth') * this.get('ratio')))

  qualityTitle: ->
    switch this.get('quality')
      when 'base' then 'SD'
      when 'hd' then 'HD'
      else this.get('quality').charAt(0).toUpperCase() + this.get('quality').slice(1);

  formatQuality: ->
    "#{this.get('format')}_#{this.get('quality')}"

  needDataQualityAttribute: ->
    !_.include(['base', 'mobile'], this.get('quality'))

class MSVVideoCodeGenerator.Collections.Sources extends Backbone.Collection
  model: MSVVideoCodeGenerator.Models.Source

  mp4Base: ->
    this.byFormatAndQuality(['mp4', 'base'])

  mp4Mobile: ->
    mobileSource = this.byFormatAndQuality(['mp4', 'mobile'])
    if mobileSource && mobileSource.get('isUsed') && mobileSource.get('src') isnt '' then mobileSource else this.mp4Base()

  hdPresent: ->
    sources = this.allByQuality('hd')
    sources.length && _.find sources, (source) -> source.get('isUsed') && source.get('src') isnt ''

  # Finders
  allByFormat: (format) ->
    this.select (source) -> source.get('format') is format

  allByQuality: (quality) ->
    this.select (source) -> source.get('quality') is quality

  allNonBase: ->
    this.select (source) -> source.get('quality') isnt 'base'

  allUsedNotEmpty: ->
    this.select (source) -> source.get('isUsed') and !source.srcIsEmpty()

  byQuality: (quality) ->
    this.find (source) -> source.get('quality') is quality

  byFormatAndQuality: (format_and_quality) ->
    this.find (source) -> source.formatQuality() is "#{format_and_quality[0]}_#{format_and_quality[1]}"

  # Return used and usable sources, sorted by MP4 first and then WebM/Ogg
  # and putting HD sources first if +startWithHd+ is true.
  sortedSources: (startWithHd) ->
    mp4Sources     = this.allByFormat('mp4')
    webmoggSources = this.allByFormat('webmogg')
    sortedSources  = []

    _.each [mp4Sources, webmoggSources], (family) ->
      baseSource   = _.find(family, (source) -> source.get('isUsed') and source.srcIsUsable() and source.get('quality') is 'base')
      hdSource     = _.find(family, (source) -> source.get('isUsed') and source.srcIsUsable() and source.get('quality') is 'hd')
      mobileSource = _.find(family, (source) -> source.get('isUsed') and source.srcIsUsable() and source.get('quality') is 'mobile')
      sources      = if startWithHd then [hdSource, baseSource] else [baseSource, hdSource]
      sortedSources.push([sources, mobileSource])

    _.compact _.flatten sortedSources

  constructParamsFromSources: (startWithHd) ->
    i = 1
    params = ""
    _.each this.sortedSources(startWithHd), (source) ->
      if source.get('isUsed') and source.srcIsEmptyOrUrl()
        params += "&src#{i}=" + encodeURIComponent("(#{source.get('quality')})#{source.get('src')}")
        i++

    params