class MySublimeVideo.Models.Video extends Backbone.Model
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

class MySublimeVideo.Models.VideoLightbox extends MySublimeVideo.Models.Video
  defaults:
    classes: 'sublime lightbox'

class MySublimeVideo.Models.VideoIframeEmbed extends MySublimeVideo.Models.Video
  defaults:
    classes: 'sublime sv_iframe_embed'
