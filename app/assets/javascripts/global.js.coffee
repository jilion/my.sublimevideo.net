#= require application

window.SublimeVideo = {}

document.observe "dom:loaded", ->
  Event.observe window, 'popstate', (event) ->
    if event.state? && event.state.hidePopup?
      SublimeVideo.showPopup(event.state.hidePopup)
    else if event.state? && event.state.showPopup?
      SublimeVideo.showPopup(event.state.showPopup)

SublimeVideo.showPopup = (name) ->
  if Cookie.get('l') == 'true'
    return true
  else if $("popup_#{name}")
    SublimeVideo.openSimplePopup("popup_#{name}")
    if history && history.pushState
      history.pushState { showPopup: name }, '', document.location.href.replace(document.location.search, '') + "?p=#{name}"

  false

SublimeVideo.hidePopup = (name) ->
  if $("popup_#{name}")
    SublimeVideo.closeSimplePopup("popup_#{name}")

  false

SublimeVideo.replaceHistory = (contentId) ->
  if history && history.replaceState
    history.replaceState { hidePopup: contentId.replace(/^popup_/, '') }, '', document.location.href.replace document.location.search, ''

SublimeVideo.openSimplePopup = (contentId) -> # item can be site
  if SublimeVideo.simplePopupHandler then SublimeVideo.simplePopupHandler.close()
  SublimeVideo.simplePopupHandler = new SimplePopupHandler(contentId, SublimeVideo.replaceHistory)
  SublimeVideo.simplePopupHandler.open()

# ====================
# = Onclick handlers =
# ====================

SublimeVideo.closeSimplePopup = (contentId) ->
  unless SublimeVideo.simplePopupHandler?
    SublimeVideo.simplePopupHandler = new SimplePopupHandler(contentId, SublimeVideo.replaceHistory)
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

SublimeVideo.makeSticky = (element, css_selector) ->
  $$("#{css_selector} .active").each (el) ->
    el.removeClassName 'active'
  element.addClassName 'active'
  if li = element.up 'li' then li.addClassName 'active'

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
