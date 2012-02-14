# No Prototype / jQuery in here !!

window.SublimeVideo =
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

window.MySublimeVideo =
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

window.AdminSublimeVideo =
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

# C IS FOR COOKIE
window.Cookie =
  get: (name) ->
    name = escape(name) + '='
    if document.cookie.indexOf(name) >= 0
      cookies = document.cookie.split(/\s*;\s*/)
      for cookie in cookies
        if cookie.indexOf(name) == 0 then return unescape cookie.substring(name.length, cookie.length)

    null

  set: (name, value, options) ->
    newcookie = [escape(name) + "=" + escape(value)]
    if options
      if options.expires then newcookie.push "expires=" + options.expires.toGMTString()
      if options.path    then newcookie.push "path=#{options.path}"
      if options.domain  then newcookie.push "domain=#{options.domain}"
      if options.secure  then newcookie.push "secure"
    document.cookie = newcookie.join '; '

SublimeVideo.capitalize = (str) ->
  str.replace(/^\w/, ($0) -> $0.toUpperCase())

class SublimeVideo.ImagePreloader
  constructor: (imageUrl, callback, options = {}) ->
    @callback = callback
    @imageSrc = imageUrl
    @options  = options
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
    @options['width']  = @image['width']
    @options['height'] = @image['height']
    @callback(@problem, @imageSrc, @options)

class SublimeVideo.VideoPreloader
  constructor: (videoUrl, callback) ->
     @callback = callback
     @videoSrc = videoUrl
     this.preload()

  preload: ->
    SublimeVideoSizeChecker.getVideoSize @videoSrc, @callback
