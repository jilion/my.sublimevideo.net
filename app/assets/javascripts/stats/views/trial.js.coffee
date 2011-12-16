class MSVStats.Views.TrialView extends Backbone.View
  template: JST['stats/templates/_trial']

  events:
    'click button': 'startTrialOrUpgrade'

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

  startTrialOrUpgrade: ->
    siteToken = MSVStats.sites.selectedSite.get('token')
    window.location.href = "/sites/#{siteToken}/plan/edit"
