class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->

    this.initHighcharts()
    this.initSparkline()
    this.initModels()
    this.initPusher()

    # MSVStats.stats.bind('reset', -> MSVStats.stats.clearCache())
    # MSVStats.period.bind('change', -> MSVStats.stats.clearCache())

    pageTitleView = new MSVStats.Views.PageTitleView(collection: MSVStats.sites)
    pageTitleView.render()
    sitesSelectView = new MSVStats.Views.SitesSelectView(collection: MSVStats.sites)
    $('#sites_select').html(sitesSelectView.render().el)

    periodSelectorMinutesView = new MSVStats.Views.PeriodSelectorMinutesView
      statsMinutes: MSVStats.statsMinutes
      period: MSVStats.period
    periodSelectorHoursView = new MSVStats.Views.PeriodSelectorHoursView
      statsHours: MSVStats.statsHours
      period: MSVStats.period
    periodSelectorDaysView = new MSVStats.Views.PeriodSelectorDaysView
      statsDays: MSVStats.statsDays
      period: MSVStats.period

    MSVStats.vvView = new MSVStats.Views.VVView
      statsMinutes: MSVStats.statsMinutes
      statsHours:   MSVStats.statsHours
      statsDays:    MSVStats.statsDays
      sites:        MSVStats.sites
      period:       MSVStats.period
    $('#vv_chart_legend').html(MSVStats.vvView.render().el)

    # window.setTimeout(( -> MSVStats.vvView.periodicRender()), 30000)
    # bpView = new MSVStats.Views.BPView(collection: MSVStats.stats, sites: MSVStats.sites, period: MSVStats.period)
    # $('#bp_legend').html(bpView.render().el)
    # mdView = new MSVStats.Views.MDView(collection: MSVStats.stats, sites: MSVStats.sites, period: MSVStats.period)
    # $('#md_legend').html(mdView.render().el)

    # updateDateView = new MSVStats.Views.UpdateDateView(collection: MSVStats.stats)
    # $('#update_date').html(updateDateView.render().el)

  routes:
    'sites/:token/stats': 'home'

  home: (token) ->
    MSVStats.period.clear()
    MSVStats.sites.select(token)
    this.resetAndFetchStats()


  initHighcharts: ->
    Highcharts.setOptions
      global:
        useUTC: false

  initSparkline: ->
    # $.fn.sparkline.defaults.line.lineColor       = '#0046ff'
    # $.fn.sparkline.defaults.line.fillColor       = '#0046ff'
    $.fn.sparkline.defaults.line.spotRadius      = 0
    $.fn.sparkline.defaults.line.lineWidth       = 0
    $.fn.sparkline.defaults.line.spotColor       = false
    $.fn.sparkline.defaults.line.minSpotColor    = false
    $.fn.sparkline.defaults.line.maxSpotColor    = false
    $.fn.sparkline.defaults.line.drawNormalOnTop = true
    $.fn.sparkline.defaults.line.chartRangeClip  = true
    # $.fn.sparkline.defaults.line.chartRangeMin   = 0
    # $.fn.sparkline.defaults.line.chartRangeMax   = 0

  initModels: ->
    MSVStats.period = new MSVStats.Models.Period()

    MSVStats.statsMinutes = new MSVStats.Collections.StatsMinutes()
    MSVStats.statsHours   = new MSVStats.Collections.StatsHours()
    MSVStats.statsDays    = new MSVStats.Collections.StatsDays()

  initPusher: ->
    MSVStats.statsChannel = MSVStats.pusher.subscribe("stats")
    MSVStats.statsChannel.bind 'tick', (data) ->
      MSVStats.statsMinutes.fetch()
      MSVStats.statsHours.fetch() if data.h
      MSVStats.statsDays.fetch() if data.d
      
  resetAndFetchStats: ->
    MSVStats.statsMinutes.reset()
    MSVStats.statsHours.reset()
    MSVStats.statsDays.reset()
    
    MSVStats.statsMinutes.fetch
      silent: true
      success: -> MSVStats.period.autosetPeriod()
    MSVStats.statsHours.fetch
      silent: true
      success: -> MSVStats.period.autosetPeriod()
    MSVStats.statsDays.fetch
      silent: true
      success: -> MSVStats.period.autosetPeriod()


