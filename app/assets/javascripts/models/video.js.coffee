class MySublimeVideo.Models.Video extends Backbone.Model
  defaults:
    origin: 'files'
    youtubeId: null
    poster: null
    sources: null
    classes: 'sublime'
    keepRatio: true
    width: 640
    height: 360

  width: ->
    this.get('width')

  height: ->
    this.get('height')

  viewable: ->
    if this.get('youtubeId') isnt null
      true
    else
      result = false
      _.each this.get('sources').allUsedNotEmpty(), (source) ->
        if source.srcIsUsable()
          result = true
          return

      result

  setKeepRatio: (keepRatio) ->
    this.set(keepRatio: keepRatio)
    this.setHeightWithRatio() if this.get('keepRatio')

  setWidth: (newWidth) ->
    newWidth = parseInt(newWidth)
    newWidth = 200 if _.isNaN(newWidth) or newWidth < 200

    this.set(width: _.min([newWidth, 852]))
    this.setHeightWithRatio() if this.get('keepRatio')
    this.trigger('change:width')

  setHeight: (newHeight) ->
    newHeight = parseInt(newHeight)
    newHeight = 100 if _.isNaN(newHeight) or newHeight < 100

    this.set(height: _.min([newHeight, 720]))
    this.setWidthWithRatio() if this.get('keepRatio')
    this.trigger('change:height')

  setHeightWithRatio: ->
    this.set(height: parseInt(this.get('width') * this.get('ratio')))

  setWidthWithRatio: ->
    this.set(width: parseInt(this.get('height') / this.get('ratio')))

class MySublimeVideo.Models.VideoLightbox extends MySublimeVideo.Models.Video
  defaults:
    classes: 'sublime lightbox'

class MySublimeVideo.Models.VideoIframeEmbed extends MySublimeVideo.Models.Video
  defaults:
    classes: 'sublime sv_iframe_embed'
