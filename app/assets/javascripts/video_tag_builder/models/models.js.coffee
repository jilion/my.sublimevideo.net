class MSVVideoTagBuilder.Models.Builder extends Backbone.Model
  defaults:
    builderClass: 'standard'
    loader: null
    video: null
    preview: null
    startWithHd: false

class MSVVideoTagBuilder.Models.Iframe extends Backbone.Model
  defaults:
    src: ""
    width: null
    height: null

class MSVVideoTagBuilder.Models.Loader extends Backbone.Model
  defaults:
    token: 'YOUR_TOKEN'
    hostname: ''
    ssl: false
