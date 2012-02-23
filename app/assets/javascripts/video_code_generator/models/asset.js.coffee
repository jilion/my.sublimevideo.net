class MSVVideoCodeGenerator.Models.Asset extends Backbone.Model
  defaults:
    src: ""
    width: null
    height: null
    ratio: null
    found: true

  srcIsEmpty: ->
    this.get('src') is ""

  srcIsUrl: ->
    /^https?:\/\/.+\.\w+(\?+.*)?$/.test this.get('src')

  srcIsEmptyOrUrl: ->
    this.srcIsEmpty() or this.srcIsUrl()
