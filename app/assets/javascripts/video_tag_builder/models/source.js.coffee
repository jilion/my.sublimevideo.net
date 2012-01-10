class MSVVideoTagBuilder.Models.Source extends Backbone.Model
  defaults:
    format: null
    formatTitle: null
    quality: "base"
    dataName: ""
    dataUID: ""
    optional: false
    isUsed: true
    src: ""
    width: null
    height: null
    ratio: null
    keepRatio: true
    embedWidth: null
    embedHeight: null

  srcIsUrl: ->
    /^https?:\/\/.+\.\w+(\?+.*)?$/.test this.get('src')

  setSrc: (src) ->
    unless src is this.get('src')
      this.set(src: src)
      this.preloadSrc() if this.formatQuality() is 'mp4_base'
      this.setDefaultDataName() unless this.get('dataName')

  setKeepRatio: (keepRatio) ->
    this.set(keepRatio: keepRatio)
    this.setEmbedHeightWithRatio() if this.get('keepRatio')

  setDefaultDataName: ->
    name = this.get('src').slice(this.get('src').lastIndexOf('/') + 1, this.get('src').lastIndexOf('.'))
    this.set(dataName: name.charAt(0).toUpperCase() + name.slice(1))

  preloadSrc: ->
    new SublimeVideo.VideoPreloader(this.get('src'), this.setDimensions)

  setDimensions: (videoSrc, dimensions) =>
    if !dimensions?
      this.set(width: 0)  unless this.get('width')
      this.set(height: 0) unless this.get('height')
      this.set(ratio: 0)  unless this.get('ratio')

    else
      newWidth  = parseInt(dimensions['width'])
      newHeight = parseInt(dimensions['height'])
      newRatio  = newHeight / newWidth

      this.set(src: videoSrc)     unless videoSrc  is this.get('src')
      this.set(width: newWidth)   unless newWidth  is this.get('width')
      this.set(height: newHeight) unless newHeight is this.get('height')
      this.set(ratio: newRatio)   unless newRatio  is this.get('ratio')

    this.setEmbedWidth(_.min([this.get('width'), 852]))

  setEmbedWidth: (newEmbedWidth) ->
    newEmbedWidth = parseInt(newEmbedWidth)
    newEmbedWidth = 200 if !_.isNumber(newEmbedWidth) || newEmbedWidth < 200
    newEmbedWidth = 2000 if newEmbedWidth > 2000

    if newEmbedWidth isnt this.get('embedWidth')
      this.set(embedWidth: newEmbedWidth)
      this.setEmbedHeightWithRatio() if this.get('keepRatio')

  setEmbedHeightWithRatio: ->
    this.set(embedHeight: parseInt(this.get('embedWidth') * this.get('ratio')))

  formatTitle: ->
    this.get('formatTitle') || this.get('format').charAt(0).toUpperCase() + this.get('format').slice(1);

  qualityTitle: ->
    switch this.get('quality')
      when 'hd' then 'HD'
      else this.get('quality').charAt(0).toUpperCase() + this.get('quality').slice(1);

  formatQuality: ->
    "#{this.get('format')}_#{this.get('quality')}"

  needDataQualityAttribute: ->
    !_.include(['base', 'mobile'], this.get('quality'))

class MSVVideoTagBuilder.Collections.Sources extends Backbone.Collection
  model: MSVVideoTagBuilder.Models.Source

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

  # Finders
  allByQuality: (quality) ->
    this.select (source) -> source.get('quality') is quality

  allNonBase: ->
    this.select (source) -> source.get('quality') isnt 'base'

  byQuality: (quality) ->
    this.find (source) -> source.get('quality') is quality

  byFormatAndQuality: (format_and_quality) ->
    this.find (source) -> source.formatQuality() is "#{format_and_quality[0]}_#{format_and_quality[1]}"

  sortedSources: (startWithHd) ->
    mp4Sources     = this.allByFormat('mp4')
    webmoggSources = this.allByFormat('webmogg')
    sortedSources  = []

    _.each [mp4Sources, webmoggSources], (family) ->
      baseSource   = _.find(family, (source) -> source.get('quality') is 'base')
      hdSource     = _.find(family, (source) -> source.get('quality') is 'hd')
      mobileSource = _.find(family, (source) -> source.get('quality') is 'mobile')
      sources      = if startWithHd then [hdSource, baseSource] else [baseSource, hdSource]
      sortedSources.push([sources, mobileSource])

    _.compact _.flatten sortedSources

  constructParamsFromSources: (startWithHd) ->
    i = 1
    params = ""
    _.each this.sortedSources(startWithHd), (source) ->
      if source.get('isUsed') and source.srcIsUrl()
        params += "&src#{i}=" + encodeURIComponent("(#{source.get('quality')})#{source.get('src')}")
        i++

    params