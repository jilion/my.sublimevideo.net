#= require application
#= require home
#= require player

document.observe "dom:loaded", ->
  if ($('browsers_box'))
    SublimeVideo.allBrowsers()

# ========================
# = Browser Image Switch =
# ========================

SublimeVideo.allBrowsers = ->
  browsersBox = $('browsers_box')

  if (Prototype.Browser.WebKit)
    if (navigator.userAgent.indexOf('Chrome') != -1)
      browsersBox.addClassName("chrome")
    else # assume Safari
      browsersBox.addClassName("safari")
  else if (Prototype.Browser.Gecko)
    browsersBox.addClassName("firefox")
  else if (Prototype.Browser.Opera)
    browsersBox.addClassName("opera")
  else # default IE
