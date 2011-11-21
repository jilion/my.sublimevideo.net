#= require jquery
#= require jquery_ujs
#= require underscore

window.SublimeVideo   = window.SublimeVideo || {}
window.MySublimeVideo = window.MySublimeVideo || {}

SublimeVideo.topDomainHost = ->
  document.location.host.split('.').slice(-2).join('.')

SublimeVideo.cropPosterframe = (imgId) ->
  setTimeout ->
    originalThumb = $("##{imgId}")

    if originalThumb.width() > originalThumb.height()
      newHeight = 54
      scaleY    = Math.round(originalThumb.height() / newHeight)
      newWidth  = Math.round(originalThumb.width() / scaleY)
      newTop    = 0
      newLeft   = Math.round((newWidth - 96) / 2)
    else
      newWidth  = 96
      scaleX    = Math.round(originalThumb.width() / newWidth)
      newHeight = Math.round(originalThumb.height() / scaleX)
      newTop    = Math.round((newHeight - 54) / 2)
      newLeft   = 0

    originalThumb.css
      position: 'absolute'
      display: 'block'
      width: "#{newWidth}px"
      height: "#{newHeight}px"
      top: "#{-newTop}px"
      left: "#{-newLeft}px"
      '-webkit-mask-position' : "#{newLeft}px #{newTop}px"
      '-o-mask-position' : "#{newLeft}px #{newTop}px"
      '-moz-mask-position' : "#{newLeft}px #{newTop}px"
      'mask-position' : "#{newLeft}px #{newTop}px"
    originalThumb.prev('a.play').find('.crop').prepend originalThumb
  , 10
