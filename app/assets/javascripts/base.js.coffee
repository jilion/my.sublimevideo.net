#= require_self

#= require_tree ./models
#= require_tree ./templates

window.MSV =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}

class MSV.ImagePreloader
  constructor: (imageUrl, callback) ->
     @callback = callback
     @imageSrc = imageUrl
     @problem  = false
     this.preload()

  preload: ->
    @image = new Image()

    @image['onload']  = this.didComplete
    @image['onerror'] = this.didFail
    @image['onabort'] = this.didAbort
    @image['src']     = @imageSrc

  didFail: =>
    @problem = true
    this.didComplete()

  didAbort: =>
    @problem = true
    this.didComplete()

  didComplete: =>
    @callback(@problem, @imageSrc, { width: @image['width'], height: @image['height'] })

class MSV.VideoPreloader
  constructor: (videoUrl, callback) ->
     @callback = callback
     @videoSrc = videoUrl
     this.preload()

  preload: ->
    SublimeVideoSizeChecker.getVideoSize @videoSrc, @callback