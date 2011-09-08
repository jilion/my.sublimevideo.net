class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->
    Highcharts.setOptions
      global:
        useUTC: false
    
    MSVStats.stats = new MSVStats.Collections.Stats()
    MSVStats.stats.bind('reset', -> MSVStats.stats.clearcurrentPeriodStatsCache())
    MSVStats.period.bind('change', -> MSVStats.stats.clearcurrentPeriodStatsCache())

    pageTitleView = new MSVStats.Views.PageTitleView(collection: MSVStats.sites)
    pageTitleView.render()
    sitesSelectView = new MSVStats.Views.SitesSelectView(collection: MSVStats.sites)
    $('#sites_select').html(sitesSelectView.render().el)
    periodsSelectView = new MSVStats.Views.PeriodsSelectView(collection: MSVStats.stats, period: MSVStats.period)
    $('#periods_select').html(periodsSelectView.render().el)
    MSVStats.vvView = new MSVStats.Views.VVView(collection: MSVStats.stats, sites: MSVStats.sites, period: MSVStats.period)
    $('#vv_numbers').html(MSVStats.vvView.render().el)
    window.setTimeout(( -> MSVStats.vvView.periodicRender()), 30000)
    bpView = new MSVStats.Views.BPView(collection: MSVStats.stats, sites: MSVStats.sites, period: MSVStats.period)
    $('#bp').html(bpView.render().el)
    mdView = new MSVStats.Views.MDView(collection: MSVStats.stats, sites: MSVStats.sites, period: MSVStats.period)
    $('#md').html(mdView.render().el)

  routes:
    'sites/:token/stats': 'home'

  home: (token) ->
    MSVStats.sites.select(token)
    MSVStats.stats.reset()
    MSVStats.stats.fetch(silent: true, success: ->
      MSVStats.period.autosetPeriod(silent: true)
      MSVStats.stats.trigger('reset')
    )

    MSVStats.pusherChannel = MSVStats.pusher.subscribe("private-#{token}")
    MSVStats.pusherChannel.bind('stats-fetch', (data) ->
      MSVStats.stats.fetch(silent: true, success: ->
        MSVStats.period.set({ minValue: '60 minutes' }, silent: true)
        MSVStats.stats.trigger('reset')
      )
    )