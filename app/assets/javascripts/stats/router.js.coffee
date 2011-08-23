class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->
    @sitesSelectView = new MSVStats.Views.SitesSelectView(collection: window.MSVStats.sites)

  routes:
    'sites/:token/stats': 'home'

  home: (token) ->
    $('#sites_select').html(@sitesSelectView.render().el)
