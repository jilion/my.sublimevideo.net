#= require application
#
#= require backbone
#= require hamlcoffee
#= require spin/jquery.spin
#= require video-size-checker/sublimevideo-size-checker.min
#= require crc32
#= require inflection
#
#= require_self
#= require_tree ./models
#= require_tree ./templates
#= require_tree ./video_code_generator

window.MSVVideoCodeGenerator =
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
