#= require jquery
#= require jquery_ujs
#= require underscore

#= require global

#= require_self

window.SV =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}

window.MSV =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}

$ ->
  # .segmented menu not accessible with jQuery, so only #menu is Stickyzed
  $('#menu li').click (event) ->
    $('#menu .active').removeClass 'active'
    $(event.target).addClass 'active'
    if li = $(event.target).parent 'li' then li.addClass 'active'

    # Needed to work on Safari (if not used, dom aren't redraw before page reloading)
    setTimeout (-> window.location.href = event.target.href), 1
    false

SublimeVideo.topDomainHost = ->
  document.location.host.split('.').slice(-2).join('.')

SublimeVideo.makeSticky = (element, cssSelector) ->
  # do nothing and handle the click event with the hackish $('#menu li').click workaround
  false

SublimeVideo.iOS = ->
  navigator.userAgent.match(/(iPhone|iPod|iPad)/)

class MSV.SimplePopupHandler
  constructor: (contentId) ->
    @contentDiv = $("##{contentId}")

  startObservers: ->
    $(document).on "keydown", { popup: this }, this.keyDown
    @contentDiv.on "click", { popup: this }, this.click

  stopObservers: ->
    $(document).off "keydown", this.keyDown
    @contentDiv.off "click", this.click

  open: ->
    this.close()

    if typeof(sublimevideo)=="object" && SublimeVideo.iOS
      sublimevideo.stop()

    @contentDiv.show()

    this.startObservers()

  close: ->
    this.stopObservers()
    @contentDiv.hide()

  keyDown: (event) ->
    switch event.which
      when 27 then event.data.popup.close() # ESC

  click: (event) ->
    if event.target is event.data.popup.contentDiv[0] then event.data.popup.close()
