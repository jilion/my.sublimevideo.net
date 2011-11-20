#= require hamlcoffee
#= require highcharts/highcharts
#= require backbone
# https://github.com/timrwood/underscore.date
#= require underscore.date
#= require spin/jquery.spin
#= require jquery.sparkline
#= require jquery.ui.datepicker.min

#= require ./base
#= require_self
#= require_tree ./stats

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