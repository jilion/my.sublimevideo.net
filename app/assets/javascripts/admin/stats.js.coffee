#= require underscore
#= require underscore.date
#= require backbone
#= require hamlcoffee
#= require spin/jquery.spin
#= require jquery.ui.datepicker.min
#= require highstock/highstock

#= require global

#= require_self
#= require_tree ../templates
#= require_tree ./stats

window.AdminSublimeVideo =
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
