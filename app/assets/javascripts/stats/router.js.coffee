class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: ->
    this.initHighcharts()
    this.initSparkline()
    this.initModels()
    this.initHelpers()
    this.initPusherStatsChannel()
    this.initViews()

    this.unsubscribePusherPrivateSiteChannel()
    MSVStats.period.clear()
    this.resetAndFetchStats()
    this.initPusherPrivateSiteChannel()

    sublimevideo.load()

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

  initViews: ->
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

    new MSVStats.Views.ExportView
      el: '#export_wrap'
      period: MSVStats.period

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
      if data.s
        secondTime = data.s * 1000
        MSVStats.period.set({
          startSecondsTime: secondTime - (2 + 59) * 1000
          endSecondsTime:   secondTime - 2 * 1000
        }, silent: true)
        MSVStats.statsSeconds.updateSeconds()
        MSVStats.videos.updateSeconds(secondTime) if MSVStats.period.isSeconds()

  initPusherPrivateSiteChannel: ->
    MSVStats.privateChannel = MSVStats.pusher.subscribe("private-#{MSVStats.site.realToken()}")

    MSVStats.privateChannel.bind 'pusher:subscription_succeeded', ->
      setTimeout MSVStats.statsSeconds.fetchOldSeconds, 2000

    MSVStats.privateChannel.bind 'stats', (data) ->
      MSVStats.statsSeconds.merge(data.site, silent: true)
      MSVStats.videos.merge(data.videos, silent: true) if MSVStats.period.isSeconds()

    MSVStats.privateChannel.bind 'video_tag', (video_tag) ->
      if (video = MSVStats.videos.get(video_tag.uid))?
        video.set(video_tag)

  unsubscribePusherPrivateSiteChannel: ->
    MSVStats.pusher.unsubscribe("private-#{MSVStats.site.realToken()}")

  resetAndFetchStats: ->
    MSVStats.statsSeconds._isShowable = false
    MSVStats.statsSeconds.reset()
    MSVStats.statsMinutes.reset()
    MSVStats.statsHours.reset()
    MSVStats.statsDays.reset()

    MSVStats.statsHours.fetch
      silent: true
      success: -> MSVStats.statsRouter.syncFetchSuccess()
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
