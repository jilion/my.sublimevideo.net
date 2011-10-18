class MSVVideoTagBuilder.Models.Video extends Backbone.Model
  defaults:
    poster: null
    sources: null
    width: null
    height: null
    classes: 'sublime'

class MSVVideoTagBuilder.Models.VideoLightbox extends MSVVideoTagBuilder.Models.Video
  defaults:
    classes: 'sublime zoom'

class MSVVideoTagBuilder.Models.VideoIframeEmbed extends MSVVideoTagBuilder.Models.Video
  defaults:
    classes: 'sublime sv_iframe_embed'
