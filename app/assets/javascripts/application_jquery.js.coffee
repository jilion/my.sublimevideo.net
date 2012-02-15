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
