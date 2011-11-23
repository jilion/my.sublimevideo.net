#= require prototype
#= require modernizr
#= require s2

#= require application
#= require home

document.observe "dom:loaded", ->
  if Cookie.get('l') == 'true' && document.location.host.split('.')[0] == 'www' # topdomain and logged-in
    SublimeVideo.handleLoggedInAutoRedirection()

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
    Cookie.set('l', 'false', { domain: ".#{SublimeVideo.topDomainHost()}"})
    document.location.href = "#{my_host}/sites"
  else if path == '/help'
    document.location.href = "#{my_host}#{path}"

SublimeVideo.showPopup = (name) ->
  if Cookie.get('l') == 'true'
    document.location.href = "http://my.#{SublimeVideo.topDomainHost()}/sites"
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
