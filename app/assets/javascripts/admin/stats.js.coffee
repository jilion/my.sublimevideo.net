#= require jquery
#= require jquery_ujs
#= require underscore

#= require backbone
#= require underscore.date
#= require hamlcoffee
#= require spin/jquery.spin
#= require jquery.sparkline
#= require jquery.ui.datepicker.min
#= require highstock/highstock

#= require_self
#= require ./stats/models/stat
#= require_tree ./stats

window.SVStats =
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
