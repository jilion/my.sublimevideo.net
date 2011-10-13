class MSVVideoTagBuilder.Models.Video extends Backbone.Model
  defaults:
    poster: null
    sources: null
    originalWidth: null
    originalHeight: null
    ratio: null
    width: null
    height: null

class MSVVideoTagBuilder.Models.Source extends Backbone.Model
  defaults:
    format: null
    formatTitle: null
    quality: "normal"
    qualityTitle: null
    optional: false
    src: ""
    originalWidth: null
    originalHeight: null
    ratio: null
    width: null
    height: null

  formatTitle: ->
    this.get('formatTitle') || this.get('format').charAt(0).toUpperCase() + this.get('format').slice(1);

  qualityTitle: ->
    this.get('qualityTitle') || this.get('quality').charAt(0).toUpperCase() + this.get('quality').slice(1);

class MSVVideoTagBuilder.Collections.Sources extends Backbone.Collection
  model: MSVVideoTagBuilder.Models.Source

class MSVVideoTagBuilder.Models.Iframe extends Backbone.Model
  defaults:
    src: ""
    width: null
    height: null

class MSVVideoTagBuilder.Models.Loader extends Backbone.Model
  defaults:
    token: 'YOUR_TOKEN'
    ssl: false
