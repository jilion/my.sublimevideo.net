class MSVVideoCodeGenerator.Models.Asset extends Backbone.Model
  defaults:
    src: ""
    found: true

  srcIsEmpty: ->
    !this.get('src')

  srcIsUrl: ->
    /^https?:\/\/.+\.\w+(\?+.*)?$/.test this.get('src')

  srcIsEmptyOrUrl: ->
    this.srcIsEmpty() or this.srcIsUrl()

  srcIsUsable: ->
    this.srcIsUrl() and this.get('found')