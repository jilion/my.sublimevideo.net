#= require_self

document.observe "dom:loaded", ->
  $$('.popup').each (popup) ->
    if popup.visible()
      SublimeVideo.simplePopupHandler = new SimplePopupHandler(popup.id)
      SublimeVideo.simplePopupHandler.startObservers()

SublimeVideo.showPopup = (name, successUrl = null) ->
  failurePath ?= ''
  successUrl ?= "#{document.location.protocol}//my.#{SublimeVideo.topDomainHost()}/sites"
  if $("popup_#{name}")
    SublimeVideo.openSimplePopup("popup_#{name}")
    $("user_#{name}").insert({ top: new Element("input", { name: "success_url", type: 'hidden', value: successUrl }) })

    if navigator.userAgent.indexOf("iPad") isnt -1
      sublimevideo.pause()
      $("popup_#{name}").down("#user_email").focus()

  false

SublimeVideo.hidePopup = (name) ->
  if $("popup_#{name}")
    SublimeVideo.closeSimplePopup("popup_#{name}")

  false

SublimeVideo.openSimplePopup = (contentId) -> # item can be site
  SublimeVideo.closeSimplePopup(contentId)
  SublimeVideo.simplePopupHandler = new SimplePopupHandler(contentId)
  SublimeVideo.simplePopupHandler.open()

# ====================
# = Onclick handlers =
# ====================

SublimeVideo.closeSimplePopup = (contentId) ->
  $$('.popup').each (popup) -> popup.hide()
  if SublimeVideo.simplePopupHandler?
    SublimeVideo.simplePopupHandler.close();

  false

class SimplePopupHandler
  constructor: (contentId) ->
    @contentId       = contentId
    @contentDiv      = $(contentId)
    @keyDownHandler  = document.on "keydown", this.keyDown.bind(this)
    @clickHandler    = @contentDiv.on "click", this.click.bind(this)

  startObservers: ->
    @keyDownHandler.start()
    @clickHandler.start()

  stopObservers: ->
    @keyDownHandler.stop()
    @clickHandler.stop()

  open: (contentId) ->
    this.close()

    if typeof(sublimevideo)=="object" && Prototype.Browser.MobileSafari
      sublimevideo.stop()

    @contentDiv.show()

    this.startObservers()

  close: ->
    this.stopObservers()
    @contentDiv.hide()

  keyDown: (event) ->
    switch event.keyCode
      when Event.KEY_ESC then this.close()

  click: (event) ->
    if event.target is @contentDiv then this.close()
