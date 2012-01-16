class SVStats.Routers.StatsRouter extends Backbone.Router

  initialize: (options) ->
    @selectedRange = 4
    this.initHighcharts()
    this.initModels()
    this.initHelpers()

    new SVStats.Views.PageTitleView
      el: '#page_title'

    SVStats.graphView = new SVStats.Views.GraphView
      el: '#chart'
      collection: SVStats.stats

    SVStats.seriesSelectorView = new SVStats.Views.SeriesSelectorView
      el: '#selectors'

  routes:
    'stats': 'home'

  home: ->
    this.fetchStats()

  initModels: ->
    SVStats.stats["users"]       = new SVStats.Collections.UsersStats()
    SVStats.stats["sites"]       = new SVStats.Collections.SitesStats()
    SVStats.stats["site_stats"]  = new SVStats.Collections.SiteStatsStats()
    SVStats.stats["site_usages"] = new SVStats.Collections.SiteUsagesStats()
    SVStats.stats["tweets"]      = new SVStats.Collections.TweetsStats()

  initHelpers: ->
    SVStats.chartsHelper = new SVStats.Helpers.ChartsHelper()

  fetchStats: ->
    _.each SVStats.stats, (stat) ->
      stat.fetch
        silent: true
        success: -> SVStats.statsRouter.syncFetchSuccess()

  syncFetchSuccess: ->
    if _.all(SVStats.stats, (e) -> e.length > 0)
      SVStats.graphView.render()

  initHighcharts: ->
    Highcharts.setOptions
      global:
        useUTC: true
