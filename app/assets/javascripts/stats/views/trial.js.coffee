class MSVStats.Views.TrialView extends Backbone.View
  template: JST['stats/templates/_trial']

  events:
    'click button': 'startTrial'

  initialize: ->
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset',  this.render
    this.render()

  render: =>
    if (selectedSite = MSVStats.sites.selectedSite)?
      MSVStats.Routers.StatsRouter.setHighchartsUTC(false) # don't use UTC date here
      $(@el).html(this.template(site: selectedSite))
      MSVStats.Routers.StatsRouter.setHighchartsUTC()
    return this

  startTrial: (event) ->
    site         = MSVStats.sites.selectedSite
    siteToken    = site.get('token')
    trialEndTime = site.statsTrialEndTime(new Date().getTime())
    MSVStats.Routers.StatsRouter.setHighchartsUTC(false) # don't use UTC date here
    if confirm("Are you sure you want to start stats trial? It'll end on #{Highcharts.dateFormat('%e %b %Y', trialEndTime)}")
      $.post "/sites/#{siteToken}/stats/trial", _method: 'PUT', ->
        MSVStats.sites.fetch # removes trial button
          success: ->
            MSVStats.sites.select(siteToken)
            MSVStats.statsRouter.home(siteToken)
    MSVStats.Routers.StatsRouter.setHighchartsUTC()