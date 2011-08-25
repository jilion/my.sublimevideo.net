class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->
    pageTitleView = new MSVStats.Views.PageTitleView(collection: MSVStats.sites)
    pageTitleView.render()
    sitesSelectView = new MSVStats.Views.SitesSelectView(collection: MSVStats.sites)
    $('#sites_select').html(sitesSelectView.render().el)
    periodsSelectView = new MSVStats.Views.PeriodsSelectView(period: MSVStats.period)
    $('#periods_select').html(periodsSelectView.render().el)
    MSVStats.stats = new MSVStats.Collections.Stats()

  routes:
    'sites/:token/stats': 'home'

  home: (token) ->
    MSVStats.sites.select(token)
    MSVStats.stats.fetch()