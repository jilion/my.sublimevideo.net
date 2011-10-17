class MSVStats.Views.TrialView extends Backbone.View
  template: JST['stats/templates/_trial']

  events:
    'click button': 'startTrial'

  initialize: ->
    _.bindAll this, 'render'
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset',  this.render
    this.render()

  render: ->
    site = MSVStats.sites.selectedSite
    if site.inFreePlan() && site.statsTrialIsActivable()
      $(@el).html(this.template())
    else
      $(@el).html('')
    return this

  startTrial: (event) ->
    site = MSVStats.sites.selectedSite
    siteToken = site.get('token')
    trialEndTime = new Date().getTime() + 7 * 24 * 3600 * 1000
    if confirm("Are you sure you want to start stats trial? It'll end on #{Highcharts.dateFormat('%e %b %Y', trialEndTime)}")
      $.post "/sites/#{siteToken}/stats/trial", ->
        site.set
          stats_trial_started_at: true
          stats_retention_days: 365
        MSVStats.sites.trigger('change')  # removes trial button
        MSVStats.statsRouter.home(siteToken)

