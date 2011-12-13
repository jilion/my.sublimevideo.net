class SVStats.Routers.StatsRouter extends Backbone.Router

  initialize: (options) ->
    this.initHighcharts()
    # this.initSparkline()
    this.initModels()
    this.initHelpers()

    new SVStats.Views.PageTitleView
      el: '#page_title'

    # new MSVStats.Views.PeriodSelectorSecondsView
    #   el: '#period_selectors .seconds'
    #   statsSeconds: MSVStats.statsSeconds
    #   period: MSVStats.period
    #   pusher: MSVStats.pusher
    # new MSVStats.Views.PeriodSelectorMinutesView
    #   el: '#period_selectors .minutes'
    #   statsMinutes: MSVStats.statsMinutes
    #   period: MSVStats.period
    # new MSVStats.Views.PeriodSelectorHoursView
    #   el: '#period_selectors .hours'
    #   statsHours: MSVStats.statsHours
    #   period: MSVStats.period
    # new MSVStats.Views.PeriodSelectorDays30View
    #   el: '#period_selectors .days30'
    #   statsDays: MSVStats.statsDays
    #   period: MSVStats.period
    # new MSVStats.Views.PeriodSelectorDays365View
    #   el: '#period_selectors .days365'
    #   statsDays: MSVStats.statsDays
    #   period: MSVStats.period
    #
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
    # MSVStats.period = new MSVStats.Models.Period()
    # MSVStats.period.bind 'change', ->
    #   if MSVStats.period.get('type')?
    #     MSVStats.Routers.StatsRouter.setHighchartsUTC()
    #     MSVStats.videos.customFetch()

    SVStats.stats["users"] = new SVStats.Collections.UsersStats()
    SVStats.stats["sites"] = new SVStats.Collections.SitesStats()
    SVStats.stats["tweets"] = new SVStats.Collections.TweetsStats()

  initHelpers: ->
    SVStats.chartsHelper = new SVStats.Helpers.ChartsHelper()

  fetchStats: ->
    SVStats.stats["users"].fetch
      silent: true
      success: -> SVStats.statsRouter.syncFetchSuccess()
    SVStats.stats["sites"].fetch
      silent: true
      success: -> SVStats.statsRouter.syncFetchSuccess()
    SVStats.stats["tweets"].fetch
      silent: true
      success: -> SVStats.statsRouter.syncFetchSuccess()

  syncFetchSuccess: ->
    if SVStats.stats["users"].length > 0 and SVStats.stats["sites"].length > 0 and SVStats.stats["tweets"].length > 0
      SVStats.graphView.render()

  initHighcharts: ->
    Highcharts.setOptions
      global:
        useUTC: true

  # initSparkline: ->
  #   # $.fn.sparkline.defaults.line.lineColor       = '#0046ff'
  #   # $.fn.sparkline.defaults.line.fillColor       = '#0046ff'
  #   $.fn.sparkline.defaults.line.spotRadius      = 0
  #   $.fn.sparkline.defaults.line.lineWidth       = 0
  #   $.fn.sparkline.defaults.line.spotColor       = false
  #   $.fn.sparkline.defaults.line.minSpotColor    = false
  #   $.fn.sparkline.defaults.line.maxSpotColor    = false
  #   $.fn.sparkline.defaults.line.drawNormalOnTop = true
  #   $.fn.sparkline.defaults.line.chartRangeClip  = true
  #   $.fn.sparkline.defaults.line.chartRangeMin   = 0
  #   # $.fn.sparkline.defaults.line.chartRangeMax   = 0
