#= require underscore.date
#= require hamlcoffee
#= require spin/jquery.spin
#= require jquery.sparkline
#= require jquery.ui.datepicker.min
#
#= require_self
#= require_tree ./stats

window.SV =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}

window.MSVStats =
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

SublimeVideo.cropPosterframe = (problem, imageSrc, options) ->
  imgId = options['imgId']
  originalThumb = $('<img />').attr('src', imageSrc).attr('id', "#{imgId}-img")

  unless problem
    if options['width'] > options['height']
      newHeight = 54
      scaleY    = Math.round(options['height'] / newHeight)
      newWidth  = Math.round(options['width'] / scaleY)
      newTop    = 0
      newLeft   = Math.round((newWidth - 96) / 2)
    else
      newWidth  = 96
      scaleX    = Math.round(options['width'] / newWidth)
      newHeight = Math.round(options['height'] / scaleX)
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
    $("##{imgId}-crop").prepend originalThumb

    originalThumbClone = originalThumb.clone()
    originalThumbClone.attr 'id', "#{imgId}-cache"

    $('#top_videos_posterframe_cache').append originalThumbClone
