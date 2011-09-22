#= require jquery
#= require jquery_ujs
#= require highcharts/highstock
#= require underscore
#= require backbone
# https://github.com/timrwood/underscore.date
#= require underscore.date
#= require spin/jquery.spin
#= require jquery.sparkline
#= require jquery.ui.datepicker.min

#= require_self
#= require_tree ./stats/models
#= require_tree ./stats/templates
#= require_tree ./stats/views
#= require ./stats/router

window.MSVStats =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}
