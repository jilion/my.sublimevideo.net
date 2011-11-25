#= require modernizr

#= require application
#= require home

document.observe "dom:loaded", ->
  if Cookie.get('l') is '1' and document.location.host.split('.')[0] is 'www' # topdomain and logged-in
    SublimeVideo.handleLoggedInAutoRedirection()

  Event.observe window, 'popstate', (event) ->
    if event.state? and event.state.hidePopup?
      SublimeVideo.showPopup(event.state.hidePopup)
    else if event.state? and event.state.showPopup?
      SublimeVideo.showPopup(event.state.showPopup)
  
  if ($('browsers_box'))
    SublimeVideo.allBrowsers()

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

SublimeVideo.showPopup = (name) ->
  if Cookie.get('l') is '1'
    document.location.href = "#{document.location.protocol}//my.#{SublimeVideo.topDomainHost()}/sites"
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


# ========================
# = Browser Image Switch =
# ========================

SublimeVideo.allBrowsers = ->
  browsersBox = $('browsers_box')
  
  if (Prototype.Browser.WebKit)
    if (navigator.userAgent.indexOf('Chrome') != -1)
      browsersBox.addClassName("chrome")
    else # assume Safari
      browsersBox.addClassName("safari")
  else if (Prototype.Browser.Gecko)
    browsersBox.addClassName("firefox")
  else if (Prototype.Browser.Opera)
    browsersBox.addClassName("opera")
  else # default IE
