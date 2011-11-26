class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->

    this.initHighcharts()
    this.initSparkline()
    this.initModels()
    this.initHelpers()
    this.initPusherStatsChannel()
    sublimevideo.load()

    new MSVStats.Views.PageTitleView
      el: 'h2'
      sites: MSVStats.sites

    new MSVStats.Views.SitesSelectTitleView
      el: '#sites_select_title'
      sites: MSVStats.sites

    new MSVStats.Views.TrialView
      el: '#trial'
      sites: MSVStats.sites

    new MSVStats.Views.PeriodSelectorSecondsView
      el: '#period_selectors .seconds'
      statsSeconds: MSVStats.statsSeconds
      period: MSVStats.period
      pusher: MSVStats.pusher
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

    new MSVStats.Views.TimeRangeTitleView
      el: '#time_range_title'
      statsSeconds: MSVStats.statsSeconds
      statsMinutes: MSVStats.statsMinutes
      statsHours:   MSVStats.statsHours
      statsDays:    MSVStats.statsDays
      period:       MSVStats.period
      sites:        MSVStats.sites

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
    ':token': 'home'

  home: (token) ->
    this.unsubscribePusherPresenceSiteChannel()
    MSVStats.period.clear()
    MSVStats.sites.select(token)
    this.handleFreePlanClass()
    this.resetAndFetchStats()
    this.initPusherPresenceSiteChannel()

  initModels: ->
    MSVStats.period = new MSVStats.Models.Period()
    MSVStats.period.bind 'change', ->
      if MSVStats.period.get('type')?
        MSVStats.Routers.StatsRouter.setHighchartsUTC()
        MSVStats.videos.customFetch()

    MSVStats.statsSeconds = new MSVStats.Collections.StatsSeconds()
    MSVStats.statsMinutes = new MSVStats.Collections.StatsMinutes()
    MSVStats.statsHours   = new MSVStats.Collections.StatsHours()
    MSVStats.statsDays    = new MSVStats.Collections.StatsDays()

    MSVStats.videos = new MSVStats.Collections.Videos()

  initHelpers: ->
    MSVStats.chartsHelper = new MSVStats.Helpers.ChartsHelper()

  initPusherStatsChannel: ->
    MSVStats.statsChannel = MSVStats.pusher.subscribe("stats")
    MSVStats.statsChannel.bind 'tick', (data) ->
      MSVStats.statsMinutes.fetch() if data.m
      MSVStats.statsHours.fetch()   if data.h
      MSVStats.statsDays.fetch()    if data.d
      if (data.m && MSVStats.period.isMinutes()) || (data.h && MSVStats.period.isHours()) || (data.d && MSVStats.period.isDays())
        MSVStats.videos.fetch()
      unless MSVStats.sites.selectedSiteIsInFreePlan()
        if data.s
          secondTime = data.s * 1000
          MSVStats.period.set({
            startSecondsTime: secondTime - (2 + 59) * 1000
            endSecondsTime:   secondTime - 2 * 1000
          }, silent: true)
          MSVStats.statsSeconds.updateSeconds()
          MSVStats.videos.updateSeconds(secondTime) if MSVStats.period.isSeconds()

  initPusherPresenceSiteChannel: ->
    if (selectedSite = MSVStats.sites.selectedSite)? && !selectedSite.isInFreePlan()
      MSVStats.presenceChannel = MSVStats.pusher.subscribe("presence-#{selectedSite.get('token')}")

      MSVStats.presenceChannel.bind 'pusher:subscription_succeeded', ->
        setTimeout MSVStats.statsSeconds.fetchOldSeconds, 2000

      MSVStats.presenceChannel.bind 'stats', (data) ->
        MSVStats.statsSeconds.merge(data.site, silent: true)
        MSVStats.videos.merge(data.videos, silent: true) if MSVStats.period.isSeconds()

      MSVStats.presenceChannel.bind 'video_tag', (data) ->
        if (video = MSVStats.videos.get(data.u))?
          video.set(data.meta_data)

  unsubscribePusherPresenceSiteChannel: ->
    if (selectedSite = MSVStats.sites.selectedSite)?
      MSVStats.pusher.unsubscribe("presence-#{selectedSite.get('token')}")

  handleFreePlanClass: ->
    if MSVStats.sites.selectedSiteIsInFreePlan()
      $('div.stats').addClass('free')
    else
      $('div.stats').removeClass('free')

  resetAndFetchStats: ->
    MSVStats.statsSeconds._isShowable = false
    MSVStats.statsSeconds.reset()
    MSVStats.statsMinutes.reset()
    MSVStats.statsHours.reset()
    MSVStats.statsDays.reset()

    MSVStats.statsHours.fetch
      silent: true
      success: -> MSVStats.statsRouter.syncFetchSuccess()
    unless MSVStats.sites.selectedSiteIsInFreePlan()
      MSVStats.statsMinutes.fetch
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
