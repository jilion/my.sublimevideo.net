class MSVVideoCodeGenerator.Models.Video extends Backbone.Model
  defaults:
    poster: null
    sources: null
    classes: 'sublime'

  width: ->
    this.get('sources').mp4Base().get('embedWidth')

  height: ->
    this.get('sources').mp4Base().get('embedHeight')

  viewable: ->
    result = false
    _.each this.get('sources').allUsedNotEmpty(), (source) ->
      if source.srcIsUsable()
        result = true
        return

    result

class MSVVideoCodeGenerator.Models.VideoLightbox extends MSVVideoCodeGenerator.Models.Video
  defaults:
    classes: 'sublime zoom'

class MSVVideoCodeGenerator.Models.VideoIframeEmbed extends MSVVideoCodeGenerator.Models.Video
  defaults:
    classes: 'sublime sv_iframe_embed'
