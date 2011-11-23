#= require jquery
#= require jquery_ujs
#= require underscore

#= require_self
#= require global

window.SublimeVideo   = window.SublimeVideo || {}
window.MySublimeVideo = window.MySublimeVideo || {}

SublimeVideo.topDomainHost = ->
  document.location.host.split('.').slice(-2).join('.')

SublimeVideo.makeSticky = (element, cssSelector) ->
  $("#{cssSelector} .active").removeClass 'active'

  $(element).addClass 'active'
  if li = $(element).parent 'li' then li.addClass 'active'
