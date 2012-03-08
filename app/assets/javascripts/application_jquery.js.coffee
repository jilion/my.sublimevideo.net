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

SublimeVideo.topDomainHost = ->
  document.location.host.split('.').slice(-2).join('.')

SublimeVideo.makeSticky = (element, cssSelector) ->
  # do nothing and handle the click event with the hackish $('#menu li').click workaround
  false

$ ->
  # .segmented menu not accessible with jQuery, so only #menu is Stickyzed
  $('#menu li').click (event) ->
    $('#menu .active').removeClass 'active'
    $(event.target).addClass 'active'
    if li = $(event.target).parent 'li' then li.addClass 'active'

    # Needed to work on Safari (if not used, dom aren't redraw before page reloading)
    setTimeout (-> window.location.href = event.target.href), 1
    false

class MSV.SimplePopupHandler
  constructor: (contentId) ->
    @contentId       = contentId
    @contentDiv      = $("##{contentId}")
    # @keyDownHandler  = 
    # @clickHandler    = 

  startObservers: ->
    $(document).on "keydown", this.keyDown
    @contentDiv.on "click", this.click

  stopObservers: ->
    $(document).off "keydown", this.keyDown
    @contentDiv.off "click", this.click

  open: (contentId) ->
    this.close()

    # if typeof(sublimevideo)=="object" && Prototype.Browser.MobileSafari
    #   sublimevideo.stop()

    @contentDiv.show()

    this.startObservers()

  close: ->
    this.stopObservers()
    @contentDiv.hide()

  keyDown: (event) ->
    switch event.which
      when 27 then this.close() # ESC

  click: (event) ->
    if event.target is @contentDiv then this.close()
