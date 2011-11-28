#= require_self

document.observe "dom:loaded", ->
  if Cookie.get('l') is '1' and document.location.host.split('.')[0] is 'www' # topdomain and logged-in
    SublimeVideo.handleLoggedInAutoRedirection()
    SublimeVideo.handleLoggedInLinksTweaking()

  $$('.popup').each (popup) ->
    if popup.visible()
      SublimeVideo.simplePopupHandler = new SimplePopupHandler(popup.id, SublimeVideo.replaceHistory)
      SublimeVideo.simplePopupHandler.startObservers()

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
    @clickHandler    = @contentDiv.on "click", this.click.bind(this)
    @onCloseCallback = onCloseCallback

  startObservers: ->
    @keyDownHandler.start()
    @clickHandler.start()

  stopObservers: ->
    @keyDownHandler.stop()
    @clickHandler.stop()

  open: (contentId) ->
    this.close()

    @contentDiv.show()

    this.startObservers()

  close: ->
    this.stopObservers()
    @onCloseCallback(@contentId)
    @contentDiv.hide()

  keyDown: (event) ->
    switch event.keyCode
      when Event.KEY_ESC then this.close()

  click: (event) ->
    if event.target is @contentDiv then this.close()