class AdminSublimeVideo.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->
    @selectedSeries = options['selectedSeries']
    this.initModels()
    this.initHelpers()
    this.initHighcharts()
    this.fetchStats()

    new AdminSublimeVideo.Views.PageTitleView
      el: '#page_title'

    AdminSublimeVideo.timeRangeTitleView = new AdminSublimeVideo.Views.TimeRangeTitleView
      el: '#time_range_title'
      period: AdminSublimeVideo.period

    new AdminSublimeVideo.Views.PeriodSelector
      el: '#period_selectors'

    AdminSublimeVideo.datePickersView = new AdminSublimeVideo.Views.DatePickersView
      el: '#date_pickers'

    AdminSublimeVideo.graphView = new AdminSublimeVideo.Views.GraphView
      el: '#chart'
      collection: AdminSublimeVideo.stats
      period: AdminSublimeVideo.period

    AdminSublimeVideo.seriesSelectorView = new AdminSublimeVideo.Views.SeriesSelectorView
      el: '#series_selectors'

  initModels: ->
    AdminSublimeVideo.period = new AdminSublimeVideo.Models.Period(type: 'days')

    AdminSublimeVideo.stats["sales"]       = new AdminSublimeVideo.Collections.SalesStats(this.selectedSeriesFor('sales'))
    AdminSublimeVideo.stats["users"]       = new AdminSublimeVideo.Collections.UsersStats(this.selectedSeriesFor('users'))
    AdminSublimeVideo.stats["sites"]       = new AdminSublimeVideo.Collections.SitesStats(this.selectedSeriesFor('sites'))
    AdminSublimeVideo.stats["site_stats"]  = new AdminSublimeVideo.Collections.SiteStatsStats(this.selectedSeriesFor('site_stats'))
    AdminSublimeVideo.stats["site_usages"] = new AdminSublimeVideo.Collections.SiteUsagesStats(this.selectedSeriesFor('site_usages'))
    AdminSublimeVideo.stats["tweets"]      = new AdminSublimeVideo.Collections.TweetsStats(this.selectedSeriesFor('tweets'))

  initHelpers: ->
    AdminSublimeVideo.chartsHelper = new AdminSublimeVideo.Helpers.ChartsHelper()

  initHighcharts: ->
    Highcharts.setOptions
      global:
        useUTC: true

  fetchStats: ->
    _.each AdminSublimeVideo.stats, (stat) ->
      stat.fetch
        silent: true
        success: -> AdminSublimeVideo.statsRouter.syncFetchSuccess()

  syncFetchSuccess: ->
    if _.all(AdminSublimeVideo.stats, (e) -> e.length > 0)
      AdminSublimeVideo.graphView.render()

  selectedSeriesFor: (statName) ->
    _.map(_.select(@selectedSeries, (selectedSerie) -> selectedSerie[0] is statName), (selectedSerie) -> _.rest(selectedSerie))
