#= require_self

document.observe "dom:loaded", ->
  if Cookie.get('l') is '1' and document.location.host.split('.')[0] is 'www' # topdomain and logged-in
    SublimeVideo.handleLoggedInAutoRedirection()
    SublimeVideo.handleLoggedInLinksTweaking()

  Event.observe window, 'popstate', (event) ->
    if event.state? and event.state.hidePopup?
      SublimeVideo.showPopup(event.state.hidePopup)
    else if event.state? and event.state.showPopup?
      SublimeVideo.showPopup(event.state.showPopup)

SublimeVideo.handleLoggedInAutoRedirection = ->
  path = document.location.pathname
  my_host = "#{document.location.protocol}//my.#{SublimeVideo.topDomainHost()}"
  if path == '/'
    # We "kill" the cookie to ensure there will be no infinite redirect between /sites and /?p=login
    # When MSV session is dead but "l" cookie is still true
    # Setting the cookie to false here will force the MyController to reset it to true if user is actually logged-in.
    Cookie.set('l', 'false', { domain: ".#{SublimeVideo.topDomainHost()}"})
    document.location.href = "#{my_host}/sites"
  else if path == '/help'
    document.location.href = "#{my_host}#{path}"

SublimeVideo.handleLoggedInLinksTweaking = ->
  $$('li.not_logged_in_only').invoke 'hide'
  $$('a.my_link').each (a) -> a.href = a.href.replace /www/, 'my'

SublimeVideo.showPopup = (name, successUrl = null) ->
  failurePath ?= ''
  successUrl ?= "#{document.location.protocol}//my.#{SublimeVideo.topDomainHost()}/sites"
  if Cookie.get('l') is '1'
    document.location.href = successUrl
  else if $("popup_#{name}")
    SublimeVideo.openSimplePopup("popup_#{name}")
    $("popup_#{name}").down('#user_email').focus()
    $("user_#{name}").insert({ top: new Element("input", { name: "success_url", type: 'hidden', value: successUrl }) })

    if history && history.pushState
      history.pushState { showPopup: name }, '', document.location.href.replace(document.location.search, '') + "?p=#{name}"

  false

SublimeVideo.hidePopup = (name) ->
  if $("popup_#{name}")
    SublimeVideo.closeSimplePopup("popup_#{name}")

  false

SublimeVideo.replaceHistory = (contentId) ->
  if history and history.replaceState
    history.replaceState { hidePopup: contentId.replace(/^popup_/, '') }, '', document.location.href.replace document.location.search, ''

SublimeVideo.openSimplePopup = (contentId) -> # item can be site
  SublimeVideo.closeSimplePopup(contentId)
  SublimeVideo.simplePopupHandler = new SimplePopupHandler(contentId, SublimeVideo.replaceHistory)
  SublimeVideo.simplePopupHandler.open()

# ====================
# = Onclick handlers =
# ====================

SublimeVideo.closeSimplePopup = (contentId) ->
  $$('.popup').each (popup) -> popup.hide()
  if SublimeVideo.simplePopupHandler?
    # SublimeVideo.simplePopupHandler = new SimplePopupHandler(contentId, SublimeVideo.replaceHistory)
    SublimeVideo.simplePopupHandler.close();

  false

class SimplePopupHandler
  constructor: (contentId, onCloseCallback) ->
    @contentId       = contentId
    @contentDiv      = $(contentId)
    @keyDownHandler  = document.on "keydown", this.keyDown.bind(this)
    @onCloseCallback = onCloseCallback

  startKeyboardObservers: ->
    @keyDownHandler.start()

  stopKeyboardObservers: ->
    @keyDownHandler.stop()

  open: (contentId) ->
    # Creates the base skeleton for the popup, and will render it's content via an ajax request:
    #
    # <div class='popup loading'>
    #   <div class='wrap'>
    #     <div class='content'></div>
    #   </div>
    #   <a class='close'><span>Close</span></a>
    # </div>
    this.close()

    @contentDiv.show()

    this.startKeyboardObservers()

  close: ->
    this.stopKeyboardObservers()
    @onCloseCallback(@contentId)
    @contentDiv.hide()

  keyDown: (event) ->
    switch event.keyCode
      when Event.KEY_ESC then this.close()

class ImagePreloader
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

class VideoPreloader
  constructor: (videoUrl, callback) ->
     @callback = callback
     @videoSrc = videoUrl
     this.preload()

  preload: ->
    SublimeVideoSizeChecker.getVideoSize @videoSrc, @callback