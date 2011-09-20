class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->
    
    this.initHighcharts()
    this.initPusher()
    
    MSVStats.stats = new MSVStats.Collections.Stats()
    MSVStats.stats.bind('reset', -> MSVStats.stats.clearCache())
    MSVStats.period.bind('change', -> MSVStats.stats.clearCache())

    pageTitleView = new MSVStats.Views.PageTitleView(collection: MSVStats.sites)
    pageTitleView.render()
    sitesSelectView = new MSVStats.Views.SitesSelectView(collection: MSVStats.sites)
    $('#sites_select').html(sitesSelectView.render().el)
    periodsSelectView = new MSVStats.Views.PeriodsSelectView(collection: MSVStats.stats, period: MSVStats.period)
    $('#periods_select').html(periodsSelectView.render().el)
    MSVStats.vvView = new MSVStats.Views.VVView(collection: MSVStats.stats, sites: MSVStats.sites, period: MSVStats.period)
    $('#vv_chart_legend').html(MSVStats.vvView.render().el)
    # window.setTimeout(( -> MSVStats.vvView.periodicRender()), 30000)
    # bpView = new MSVStats.Views.BPView(collection: MSVStats.stats, sites: MSVStats.sites, period: MSVStats.period)
    # $('#bp_legend').html(bpView.render().el)
    # mdView = new MSVStats.Views.MDView(collection: MSVStats.stats, sites: MSVStats.sites, period: MSVStats.period)
    # $('#md_legend').html(mdView.render().el)

    updateDateView = new MSVStats.Views.UpdateDateView(collection: MSVStats.stats)
    $('#update_date').html(updateDateView.render().el)

  routes:
    'sites/:token/stats': 'home'

  home: (token) ->
    $('#vv').spin()
    $('#vv_content').hide()
    # $('#bp').spin()
    # $('#bp_content').hide()
    # $('#md').spin()
    # $('#md_content').hide()

    MSVStats.sites.select(token)
    MSVStats.stats.fetch(silent: true, success: ->
      MSVStats.period.autosetPeriod(silent: true)
      MSVStats.stats.trigger('reset')
    )
  
  initHighcharts: ->
    Highcharts.setOptions
      global:
        useUTC: false
  
  initPusher: ->
    MSVStats.statsChannel = MSVStats.pusher.subscribe("stats")
    MSVStats.statsChannel.bind('tick', (data) ->
      console.log 'tick'
      console.log data
      # MSVStats.stats.fetch(silent: true, success: ->
      #   MSVStats.period.set({ minValue: '60 minutes' }, silent: true)
      #   MSVStats.stats.trigger('reset')
      # )
    )

