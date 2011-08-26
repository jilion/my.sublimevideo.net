#= require jquery
#= require jquery_ujs
#= require highcharts/highcharts
#= require underscore
#= require backbone

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