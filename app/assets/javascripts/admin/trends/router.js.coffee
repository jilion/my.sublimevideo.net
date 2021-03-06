class AdminSublimeVideo.Routers.TrendsRouter extends Backbone.Router
  initialize: (options) ->
    @selectedPeriod = options['selectedPeriod']
    @selectedSeries = options['selectedSeries']
    this.initModels()
    this.initHelpers()
    this.initHighcharts()
    this.initKeyboardShortcuts()
    this.fetchTrends()

    AdminSublimeVideo.timeRangeTitleView = new AdminSublimeVideo.Views.TimeRangeTitleView
      el: '#time_range_title'

    new AdminSublimeVideo.Views.PeriodSelectorView
      el: '#period_selectors'

    AdminSublimeVideo.datePickersView = new AdminSublimeVideo.Views.DatePickersView
      el: '#date_pickers'

    AdminSublimeVideo.graphView = new AdminSublimeVideo.Views.GraphView
      el: '#chart'
      collection: AdminSublimeVideo.trends

    AdminSublimeVideo.seriesSelectorView = new AdminSublimeVideo.Views.SeriesSelectorView
      el: '#series_selectors'

  initModels: ->
    AdminSublimeVideo.period = new AdminSublimeVideo.Models.Period
    unless _.isEmpty @selectedPeriod
      AdminSublimeVideo.period.set
        start: new Date(parseInt(@selectedPeriod[0]))
        end: new Date(parseInt(@selectedPeriod[1]))

    AdminSublimeVideo.trends["billings"]                    = new AdminSublimeVideo.Collections.BillingsTrends(this.selectedSeriesFor('billings'))
    AdminSublimeVideo.trends["revenues"]                    = new AdminSublimeVideo.Collections.RevenuesTrends(this.selectedSeriesFor('revenues'))
    AdminSublimeVideo.trends["billable_items"]              = new AdminSublimeVideo.Collections.BillableItemsTrends(this.selectedSeriesFor('billable_items'))
    AdminSublimeVideo.trends["users"]                       = new AdminSublimeVideo.Collections.UsersTrends(this.selectedSeriesFor('users'))
    AdminSublimeVideo.trends["sites"]                       = new AdminSublimeVideo.Collections.SitesTrends(this.selectedSeriesFor('sites'))
    AdminSublimeVideo.trends["site_admin_stats"]            = new AdminSublimeVideo.Collections.SiteAdminStatsTrends(this.selectedSeriesFor('site_admin_stats'))
    AdminSublimeVideo.trends["site_usages"]                 = new AdminSublimeVideo.Collections.SiteUsagesTrends(this.selectedSeriesFor('site_usages'))
    AdminSublimeVideo.trends["tweets"]                      = new AdminSublimeVideo.Collections.TweetsTrends(this.selectedSeriesFor('tweets'))
    AdminSublimeVideo.trends["tailor_made_player_requests"] = new AdminSublimeVideo.Collections.TailorMadePlayerRequestsTrends(this.selectedSeriesFor('tailor_made_player_requests'))
    AdminSublimeVideo.totals = {}

  initHelpers: ->
    AdminSublimeVideo.chartsHelper = new AdminSublimeVideo.Helpers.ChartsHelper()

  initHighcharts: ->
    Highcharts.setOptions
      global:
        useUTC: true

  initKeyboardShortcuts: ->
    Mousetrap.bind 'r', =>
      _.each AdminSublimeVideo.trends, (collection) -> collection.selected = []
      $('a.selector').removeClass('active')
      MySublimeVideo.Helpers.HistoryHelper.clearQueryInUrl()
      AdminSublimeVideo.graphView.render() # redraw the chart

  fetchTrends: ->
    @fetchedTrendsCount = 0
    _.each AdminSublimeVideo.trends, (trend) ->
      trend.fetch
        silent: true
        success: -> AdminSublimeVideo.trendsRouter.syncFetchSuccess()

  syncFetchSuccess: ->
    @fetchedTrendsCount += 1
    AdminSublimeVideo.graphView.render() if @fetchedTrendsCount is _.size(AdminSublimeVideo.trends)

  selectedSeriesFor: (trendName) ->
    _.map(_.select(@selectedSeries, (selectedSerie) -> selectedSerie[0] is trendName), (selectedSerie) -> _.rest(selectedSerie))
