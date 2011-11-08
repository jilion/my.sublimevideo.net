class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->

    this.initHighcharts()
    this.initSparkline()
    this.initModels()
    this.initPusherTick()

    new MSVStats.Views.PageTitleView
      el: 'h2'
      sites: MSVStats.sites

    new MSVStats.Views.SiteQuickSwitchView
      el: '#site_quick_switch'
      sites: MSVStats.sites

    new MSVStats.Views.TrialView
      el: '#trial'
      sites: MSVStats.sites

    new MSVStats.Views.PeriodSelectorSecondsView
      el: '#period_selectors .seconds'
      statsSeconds: MSVStats.statsSeconds
      period: MSVStats.period
    new MSVStats.Views.PeriodSelectorMinutesView
      el: '#period_selectors .minutes'
      statsMinutes: MSVStats.statsMinutes
      period: MSVStats.period
    new MSVStats.Views.PeriodSelectorHoursView
      el: '#period_selectors .hours'
      statsHours: MSVStats.statsHours
      period: MSVStats.period
    new MSVStats.Views.PeriodSelectorDays30View
      el: '#period_selectors .days30'
      statsDays: MSVStats.statsDays
      period: MSVStats.period
    new MSVStats.Views.PeriodSelectorDays365View
      el: '#period_selectors .days365'
      statsDays: MSVStats.statsDays
      period: MSVStats.period

    new MSVStats.Views.DatesRangeTitleView
      el: '#dates_range_title'
      statsSeconds: MSVStats.statsSeconds
      statsMinutes: MSVStats.statsMinutes
      statsHours:   MSVStats.statsHours
      statsDays:    MSVStats.statsDays
      period:       MSVStats.period

    MSVStats.datePickersView = new MSVStats.Views.DatePickersView
      el: '#date_pickers'

    new MSVStats.Views.VVView
      el: '#vv_chart_legend'
      statsSeconds: MSVStats.statsSeconds
      statsMinutes: MSVStats.statsMinutes
      statsHours:   MSVStats.statsHours
      statsDays:    MSVStats.statsDays
      period:       MSVStats.period

    new MSVStats.Views.TopVideosView
      el: '#top_videos_content'
      period: MSVStats.period
      videos: MSVStats.videos
    
    new MSVStats.Views.BPView
      el: '#bp_content'
      statsSeconds: MSVStats.statsSeconds
      statsMinutes: MSVStats.statsMinutes
      statsHours:   MSVStats.statsHours
      statsDays:    MSVStats.statsDays
      period:       MSVStats.period

    new MSVStats.Views.MDView
      el: '#md_content'
      statsSeconds: MSVStats.statsSeconds
      statsMinutes: MSVStats.statsMinutes
      statsHours:   MSVStats.statsHours
      statsDays:    MSVStats.statsDays
      period:       MSVStats.period

    new MSVStats.Views.PlanUsageView
      el: '#plan_usage'
      statsDays: MSVStats.statsDays

  routes:
    'sites/:token/stats': 'home'

  home: (token) ->
    MSVStats.selectedSiteToken = token
    MSVStats.period.clear()
    MSVStats.sites.select(token)
    this.resetAndFetchStats()
    this.initPusherStats()

  initModels: ->
    MSVStats.period = new MSVStats.Models.Period()
    MSVStats.period.bind 'change', ->
      MSVStats.Routers.StatsRouter.setHighchartsUTC()
      MSVStats.videos.fetch() if MSVStats.period.get('type')?
      
    MSVStats.statsSeconds = new MSVStats.Collections.StatsSeconds()
    MSVStats.statsMinutes = new MSVStats.Collections.StatsMinutes()
    MSVStats.statsHours   = new MSVStats.Collections.StatsHours()
    MSVStats.statsDays    = new MSVStats.Collections.StatsDays()
    
    MSVStats.videos = new MSVStats.Collections.Videos()

  initPusherTick: ->
    MSVStats.statsChannel = MSVStats.pusher.subscribe("stats")
    MSVStats.statsChannel.bind 'tick', (data) ->
      MSVStats.statsMinutes.fetch()
      MSVStats.statsHours.fetch() if data.h
      MSVStats.statsDays.fetch() if data.d
      MSVStats.videos.fetch()

  initPusherStats: ->
    unless MSVStats.sites.selectedSite.inFreePlan()
      MSVStats.presenceChannel = MSVStats.pusher.subscribe("presence-#{MSVStats.selectedSiteToken}")

      MSVStats.presenceChannel.bind 'pusher:subscription_succeeded', ->
        MSVStats.statsSeconds.fetch
          success: -> setTimeout((-> MSVStats.statsSeconds.updateEachSeconds()), 1000)

      MSVStats.presenceChannel.bind 'stats', (data) ->
        MSVStats.statsSeconds.merge(data.site, silent: true)

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
    unless MSVStats.sites.selectedSite.inFreePlan()
      MSVStats.statsDays.fetch
        silent: true
        success: -> MSVStats.statsRouter.syncFetchSuccess()

  syncFetchSuccess: ->
    if MSVStats.Collections.Stats.allPresent()
      MSVStats.period.autosetPeriod ->
        # MSVStats.videos.fetch()

  initHighcharts: ->
    Highcharts.setOptions
      global:
        useUTC: false

  @setHighchartsUTC: (useUTC) ->
    # console.log useUTC
    # console.log MSVStats.period.get('type') == 'days'
    # console.lgo if useUTC? then MSVStats.period.get('type') == 'days' else useUTC
    Highcharts.setOptions
      global:
        useUTC: if useUTC? then useUTC else MSVStats.period.get('type') == 'days'

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
