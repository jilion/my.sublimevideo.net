class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->

    this.initHighcharts()
    this.initSparkline()
    this.initModels()
    this.initPusherStatsChannel()
    sublimevideo.load()

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

    MSVStats.topVideosView = new MSVStats.Views.TopVideosView
      el: '#top_videos_content'
      period: MSVStats.period
      videos: MSVStats.videos

    MSVStats.playableVideoView = new MSVStats.Views.PlayableVideoView
      el: '#playable_video'

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
    this.initPusherPrivateSiteChannel()

  initModels: ->
    MSVStats.period = new MSVStats.Models.Period()
    MSVStats.period.bind 'change', ->
      MSVStats.Routers.StatsRouter.setHighchartsUTC()
      MSVStats.videos.clearCollectionAttributes()
      if MSVStats.period.get('type')?
        if MSVStats.period.isSeconds()
          MSVStats.videos.reset()
        else
          MSVStats.videos.fetch()

    MSVStats.statsSeconds = new MSVStats.Collections.StatsSeconds()
    MSVStats.statsMinutes = new MSVStats.Collections.StatsMinutes()
    MSVStats.statsHours   = new MSVStats.Collections.StatsHours()
    MSVStats.statsDays    = new MSVStats.Collections.StatsDays()

    MSVStats.videos = new MSVStats.Collections.Videos()

  initPusherStatsChannel: ->
    MSVStats.statsChannel = MSVStats.pusher.subscribe("stats")
    MSVStats.statsChannel.bind 'tick', (data) ->
      MSVStats.statsMinutes.fetch() if data.m
      MSVStats.statsHours.fetch()   if data.h
      MSVStats.statsDays.fetch()    if data.d
      if (data.m && MSVStats.period.isMinutes()) || (data.h && MSVStats.period.isHours()) || (data.d && MSVStats.period.isDays())
        MSVStats.videos.fetch()
      unless MSVStats.sites.selectedSite.inFreePlan()
        if data.s
          secondTime = data.s * 1000
          MSVStats.statsSeconds.updateSeconds(secondTime)
          MSVStats.videos.updateSeconds(secondTime) if MSVStats.period.isSeconds()

  initPusherPrivateSiteChannel: ->
    unless MSVStats.sites.selectedSite.inFreePlan()
      MSVStats.privateChannel = MSVStats.pusher.subscribe("private-#{MSVStats.selectedSiteToken}")
      MSVStats.privateChannel.bind 'stats', (data) ->
        MSVStats.statsSeconds.merge(data.site, silent: true)
        MSVStats.videos.merge(data.videos, silent: true) if MSVStats.period.isSeconds()
      MSVStats.privateChannel.bind 'video_tags', (data) ->
        if (video = MSVStats.videos.get(data.u))?
          video.set(data.meta_data)

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
      MSVStats.period.autosetPeriod()

  initHighcharts: ->
    Highcharts.setOptions
      global:
        useUTC: false

  @setHighchartsUTC: (useUTC) ->
    Highcharts.setOptions
      global:
        useUTC: if useUTC? then useUTC else MSVStats.period.isDays()

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
