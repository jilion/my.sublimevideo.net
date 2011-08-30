class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->
    MSVStats.stats = new MSVStats.Collections.Stats()

    pageTitleView = new MSVStats.Views.PageTitleView(collection: MSVStats.sites)
    pageTitleView.render()
    sitesSelectView = new MSVStats.Views.SitesSelectView(collection: MSVStats.sites)
    $('#sites_select').html(sitesSelectView.render().el)
    periodsSelectView = new MSVStats.Views.PeriodsSelectView(period: MSVStats.period)
    $('#periods_select').html(periodsSelectView.render().el)
    vvView = new MSVStats.Views.VVView(collection: MSVStats.stats, sites: MSVStats.sites, period: MSVStats.period)
    $('#vv').html(vvView.render().el)
    bpView = new MSVStats.Views.BPView(collection: MSVStats.stats, sites: MSVStats.sites, period: MSVStats.period)
    $('#bp').html(bpView.render().el)
    mdView = new MSVStats.Views.MDView(collection: MSVStats.stats, sites: MSVStats.sites, period: MSVStats.period)
    $('#md').html(mdView.render().el)

  routes:
    'sites/:token/stats': 'home'

  home: (token) ->
    MSVStats.sites.select(token)
    MSVStats.stats.reset()
    MSVStats.stats.fetch()
