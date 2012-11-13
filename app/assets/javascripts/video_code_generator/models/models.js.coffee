class MSVVideoCodeGenerator.Models.Iframe extends MySublimeVideo.Models.Asset
  defaults:
    src: ''
    width: null
    height: null

class MSVVideoCodeGenerator.Models.Loader extends Backbone.Model
  defaults:
    site: null
    ssl: false
