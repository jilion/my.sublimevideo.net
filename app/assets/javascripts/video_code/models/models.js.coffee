class MSVVideoCode.Models.Iframe extends MySublimeVideo.Models.Asset
  defaults:
    src: ''
    width: null
    height: null

class MSVVideoCode.Models.Loader extends Backbone.Model
  defaults:
    site: null
    ssl: false
