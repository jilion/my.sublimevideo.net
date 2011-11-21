#= require jquery
#= require jquery_ujs
#= require underscore

window.SublimeVideo   = window.SublimeVideo || {}
window.MySublimeVideo = window.MySublimeVideo || {}

SublimeVideo.topDomainHost = ->
  document.location.host.split('.').slice(-2).join('.')

