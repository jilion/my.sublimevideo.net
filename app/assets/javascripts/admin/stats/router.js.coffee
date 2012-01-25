class AdminSublimeVideo.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->
    @selectedRange = 4
    this.initHighcharts()
    this.initModels()
    this.initHelpers()
    this.chartHeight = 400

    new AdminSublimeVideo.Views.PageTitleView
      el: '#page_title'

    new AdminSublimeVideo.Views.TimeRangeTitleView
      el: '#time_range_title'
      period: AdminSublimeVideo.period

    AdminSublimeVideo.datePickersView = new AdminSublimeVideo.Views.DatePickersView
      el: '#date_pickers'

    AdminSublimeVideo.graphView = new AdminSublimeVideo.Views.GraphView
      el: '#chart'
      collection: AdminSublimeVideo.stats

    AdminSublimeVideo.seriesSelectorView = new AdminSublimeVideo.Views.SeriesSelectorView
      el: '#selectors'

  routes:
    'stats': 'home'

  home: ->
    this.fetchStats()

  storeCurrentExtremes: ->
    if AdminSublimeVideo.statsChart?
      @xAxisMin = AdminSublimeVideo.statsChart.xAxis[0].getExtremes()['min']
      @xAxisMax = AdminSublimeVideo.statsChart.xAxis[0].getExtremes()['max']

  initModels: ->
    AdminSublimeVideo.period = new AdminSublimeVideo.Models.Period(type: 'days')

    AdminSublimeVideo.stats["users"]       = new AdminSublimeVideo.Collections.UsersStats()
    AdminSublimeVideo.stats["sites"]       = new AdminSublimeVideo.Collections.SitesStats()
    AdminSublimeVideo.stats["site_stats"]  = new AdminSublimeVideo.Collections.SiteStatsStats()
    AdminSublimeVideo.stats["site_usages"] = new AdminSublimeVideo.Collections.SiteUsagesStats()
    AdminSublimeVideo.stats["tweets"]      = new AdminSublimeVideo.Collections.TweetsStats()

  initHelpers: ->
    AdminSublimeVideo.chartsHelper = new AdminSublimeVideo.Helpers.ChartsHelper()

  fetchStats: ->
    _.each AdminSublimeVideo.stats, (stat) ->
      stat.fetch
        silent: true
        success: -> AdminSublimeVideo.statsRouter.syncFetchSuccess()

  syncFetchSuccess: ->
    if _.all(AdminSublimeVideo.stats, (e) -> e.length > 0)
      AdminSublimeVideo.graphView.render()

  initHighcharts: ->
    Highcharts.setOptions
      global:
        useUTC: true
