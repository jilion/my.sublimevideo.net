#= require application_jquery

#= require backbone
#= require hamlcoffee
#= require video-size-checker/sublimevideo-size-checker.min.js
#= require crc32
#= require inflection
#= require spin/jquery.spin

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