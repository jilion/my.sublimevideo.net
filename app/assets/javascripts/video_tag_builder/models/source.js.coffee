class MSVVideoTagBuilder.Models.Source extends Backbone.Model
  defaults:
    format: null
    formatTitle: null
    quality: "normal"
    optional: false
    isUsed: true
    src: ""
    originalWidth: null
    originalHeight: null
    ratio: null
    keepRatio: true
    embedWidth: null
    embedHeight: null

  srcIsUrl: ->
    /^https?:\/\/.+\.\w+(\?+.*)?$/.test this.get('src')

  setSrc: (src) ->
    unless src is this.get('src')
      this.set(src: src)
      this.preloadSrc() if this.formatQuality() is 'mp4_normal'

  setKeepRatio: (keepRatio) ->
    this.set(keepRatio: keepRatio)
    this.setEmbedWidth(this.get('width')) if this.get('keepRatio')
    
  preloadSrc: ->
    new MSV.VideoPreloader(this.get('src'), this.setDimensions)

  setDimensions: (videoSrc, dimensions) =>
    if dimensions?
      newWidth  = parseInt(dimensions['width'])
      newHeight = parseInt(dimensions['height'])
      newRatio  = newHeight / newWidth

      this.set(src: videoSrc) if videoSrc != this.get('src')
      this.set(width: newWidth) if newWidth != this.get('width')
      this.set(height: newHeight) if newHeight != this.get('height')
      this.set(ratio: newRatio) if newRatio != this.get('ratio')

      this.setEmbedWidth(this.get('width'))

  setEmbedWidth: (newEmbedWidth) ->
    newEmbedWidth = if _.isNumber(parseInt(newEmbedWidth)) then parseInt(newEmbedWidth) else 0
    if newEmbedWidth != this.get('embedWidth')
      this.set(embedWidth: newEmbedWidth)
      this.set(embedHeight: parseInt(this.get('embedWidth') * this.get('ratio'))) if this.get('keepRatio')

  formatTitle: ->
    this.get('formatTitle') || this.get('format').charAt(0).toUpperCase() + this.get('format').slice(1);

  qualityTitle: ->
    switch this.get('quality')
      when 'hd' then 'HD'
      else this.get('quality').charAt(0).toUpperCase() + this.get('quality').slice(1);

  formatQuality: ->
    "#{this.get('format')}_#{this.get('quality')}"

class MSVVideoTagBuilder.Collections.Sources extends Backbone.Collection
  model: MSVVideoTagBuilder.Models.Source

  mp4Normal: ->
    this.findByFormatAndQuality(['mp4', 'normal'])
    
  nonNormal: ->
    this.select (source) -> source.get('quality') isnt 'normal'

  findByFormatAndQuality: (format_and_quality) ->
    this.find (source) -> source.formatQuality() is "#{format_and_quality[0]}_#{format_and_quality[1]}"
