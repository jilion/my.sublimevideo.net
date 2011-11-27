#= require application_jquery

#= require backbone
#= require underscore.date
#= require hamlcoffee
#= require spin/jquery.spin
#= require jquery.sparkline
#= require jquery.ui.datepicker.min
#= require highcharts/highcharts

#= require base
#= require_self
#= require_tree ./stats/models
# require_tree ./stats/templates
#= require_tree ./stats/helpers
#= require_tree ./stats/views
#= require stats/router

window.MSVStats =
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

window.spinOptions =
  color:  '#d5e5ff'
  lines:  10
  length: 5
  width:  4
  radius: 8
  speed:  1
  trail:  60
  shadow: false

SublimeVideo.cropPosterframe = (imgId) ->
  originalThumb = $("##{imgId}-img")

  unless $("##{imgId}-cache").size() > 0
    setTimeout ->
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
      $("##{imgId}-crop").prepend originalThumb

      originalThumbClone = originalThumb.clone()
      originalThumbClone.attr 'id', "#{imgId}-cache"

      $('#top_videos_posterframe_cache').append originalThumbClone
    , 25
