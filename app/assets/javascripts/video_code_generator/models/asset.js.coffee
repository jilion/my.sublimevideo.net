class MSVVideoCodeGenerator.Models.Asset extends Backbone.Model
  srcIsEmpty: ->
    !this.get('src')

  srcIsUrl: ->
    /^https?:\/\/.+\.\w+(\?+.*)?$/.test this.get('src')

  srcIsEmptyOrUrl: ->
    this.srcIsEmpty() or this.srcIsUrl()
