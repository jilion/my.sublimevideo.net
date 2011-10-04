class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->

    this.initHighcharts()
    this.initSparkline()
    this.initModels()
    this.initPusherTick()

    new MSVStats.Views.PageTitleView(sites: MSVStats.sites)
    new MSVStats.Views.SitesSelectView(sites: MSVStats.sites)

    new MSVStats.Views.PeriodSelectorSecondsView
      statsSeconds: MSVStats.statsSeconds
      period: MSVStats.period
    new MSVStats.Views.PeriodSelectorMinutesView
      statsMinutes: MSVStats.statsMinutes
      period: MSVStats.period
    new MSVStats.Views.PeriodSelectorHoursView
      statsHours: MSVStats.statsHours
      period: MSVStats.period
    new MSVStats.Views.PeriodSelectorDays30View
      statsDays: MSVStats.statsDays
      period: MSVStats.period
    new MSVStats.Views.PeriodSelectorDaysView
      statsDays: MSVStats.statsDays
      period: MSVStats.period

    new MSVStats.Views.DatesRangeTitleView
      statsSeconds: MSVStats.statsSeconds
      statsMinutes: MSVStats.statsMinutes
      statsHours:   MSVStats.statsHours
      statsDays:    MSVStats.statsDays
      period:       MSVStats.period

    new MSVStats.Views.VVView
      statsSeconds: MSVStats.statsSeconds
      statsMinutes: MSVStats.statsMinutes
      statsHours:   MSVStats.statsHours
      statsDays:    MSVStats.statsDays
      period:       MSVStats.period

    new MSVStats.Views.BPView
      statsSeconds: MSVStats.statsSeconds
      statsMinutes: MSVStats.statsMinutes
      statsHours:   MSVStats.statsHours
      statsDays:    MSVStats.statsDays
      period:       MSVStats.period

    new MSVStats.Views.MDView
      statsSeconds: MSVStats.statsSeconds
      statsMinutes: MSVStats.statsMinutes
      statsHours:   MSVStats.statsHours
      statsDays:    MSVStats.statsDays
      period:       MSVStats.period

    # updateDateView = new MSVStats.Views.UpdateDateView(collection: MSVStats.stats)
    # $('#update_date').html(updateDateView.render().el)

  routes:
    'sites/:token/stats': 'home'

  home: (token) ->
    MSVStats.selectedSiteToken = token
    MSVStats.period.clear()
    MSVStats.sites.select(token)
    this.resetAndFetchStats()
    MSVStats.statsRouter.initPusherStats()

  initModels: ->
    MSVStats.period = new MSVStats.Models.Period()

    MSVStats.statsSeconds = new MSVStats.Collections.StatsSeconds()
    MSVStats.statsMinutes = new MSVStats.Collections.StatsMinutes()
    MSVStats.statsHours   = new MSVStats.Collections.StatsHours()
    MSVStats.statsDays    = new MSVStats.Collections.StatsDays()

  initPusherTick: ->
    MSVStats.statsChannel = MSVStats.pusher.subscribe("stats")
    MSVStats.statsChannel.bind 'tick', (data) ->
      MSVStats.statsMinutes.fetch()
      MSVStats.statsHours.fetch() if data.h
      MSVStats.statsDays.fetch() if data.d

  initPusherStats: ->
    MSVStats.presenceChannel = MSVStats.pusher.subscribe("presence-#{MSVStats.selectedSiteToken}")

    MSVStats.presenceChannel.bind 'pusher:subscription_succeeded', ->
      MSVStats.statsSeconds.fetch
        success: -> setTimeout("MSVStats.statsSeconds.updateEachSeconds();", 1000)

    MSVStats.presenceChannel.bind 'stats', (data) ->
      MSVStats.statsSeconds.merge(data, silent: true)

  resetAndFetchStats: ->
    MSVStats.statsSeconds.reset()
    MSVStats.statsMinutes.reset()
    MSVStats.statsHours.reset()
    MSVStats.statsDays.reset()

    MSVStats.statsMinutes.fetch
      silent: true
      success: -> MSVStats.statsRouter.syncFetchSuccess()
    MSVStats.statsHours.fetch
      silent: true
      success: -> MSVStats.statsRouter.syncFetchSuccess()
    MSVStats.statsDays.fetch
      silent: true
      success: -> MSVStats.statsRouter.syncFetchSuccess()

  syncFetchSuccess: ->
    if MSVStats.Collections.Stats.allPresent()
      MSVStats.period.autosetPeriod()

  initHighcharts: ->
    Highcharts.setOptions
      global:
        useUTC: true

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
    $.fn.sparkline.defaults.line.chartRangeMin   = 0
    # $.fn.sparkline.defaults.line.chartRangeMax   = 0
