class MSVVideoCodeGenerator.Models.Builder extends Backbone.Model
  defaults:
    builderClass: 'standard'
    startWithHd: false

class MSVVideoCodeGenerator.Models.Iframe extends Backbone.Model
  defaults:
    src: ""
    width: null
    height: null

class MSVVideoCodeGenerator.Models.Loader extends Backbone.Model
  defaults:
    site: null
    ssl: false
