class MSVVideoCodeGenerator.Models.Video extends Backbone.Model
  defaults:
    poster: null
    sources: null
    width: null
    height: null
    classes: 'sublime'

class MSVVideoCodeGenerator.Models.VideoLightbox extends MSVVideoCodeGenerator.Models.Video
  defaults:
    classes: 'sublime zoom'

class MSVVideoCodeGenerator.Models.VideoIframeEmbed extends MSVVideoCodeGenerator.Models.Video
  defaults:
    classes: 'sublime sv_iframe_embed'
