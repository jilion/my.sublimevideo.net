#= require application

window.SublimeVideo = {}

document.observe "dom:loaded", ->
  if Cookie.get('l') == 'true'
    if document.location.host.split('.').length == 2 # topdomain and logged-in
      SublimeVideo.handleLoggedInAutoRedirection()
    SublimeVideo.handleLoggedInLinksModification()

  Event.observe window, 'popstate', (event) ->
    if event.state? && event.state.hidePopup?
      SublimeVideo.showPopup(event.state.hidePopup)
    else if event.state? && event.state.showPopup?
      SublimeVideo.showPopup(event.state.showPopup)

SublimeVideo.handleLoggedInAutoRedirection = ->
  path = document.location.pathname
  my_host = "http://my.#{document.location.host}"
  if path == '/'
    # We "kill" the cookie to ensure there will be no infinite redirect between /sites and /?p=login
    # When MSV session is dead but "l" cookie is still true
    # Setting the cookie to false here will force the MyController to reset it to true if user is actually logged-in.
    Cookie.set('l', 'false', { domain: ".#{document.location.host.split('.').slice(-2).join('.')}"})
    document.location.href = "#{my_host}/sites"
  else if path == '/help'
    document.location.href = "#{my_host}#{path}"

SublimeVideo.handleLoggedInLinksModification = ->
  $('footer_home').hide()
  $$('.my_li').each (li) ->
    a = li.down('a')
    a.href = a.href.replace(/sublimevideo/, 'my.sublimevideo')

SublimeVideo.showPopup = (name) ->
  if Cookie.get('l') == 'true'
    document.location.href = "http://my.#{document.location.host.split('.').slice(-2).join('.')}/sites"
  else if $("popup_#{name}")
    SublimeVideo.openSimplePopup("popup_#{name}")
    $("popup_#{name}").down('#user_email').focus()
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
