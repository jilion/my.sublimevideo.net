class MySublimeVideo.Models.Asset extends Backbone.Model
  defaults:
    src: ''
    found: true
    ratio: 1

  srcIsEmpty: ->
    !this.get('src')

  srcIsUrl: ->
    /^(https?:)?\/\//.test this.get('src')

  srcIsEmptyOrUrl: ->
    this.srcIsEmpty() or this.srcIsUrl()

  srcIsUsable: ->
    this.srcIsUrl() and this.get('found')

  reset: ->
    this.set({
      src: ''
      found: true
      ratio: 1
    }, silent: true)
