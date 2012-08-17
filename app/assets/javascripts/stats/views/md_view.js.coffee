class MSVStats.Views.MDView extends Backbone.View
  template: JST['stats/templates/_md']

  initialize: () ->
    @options.period.bind 'change', this.render
    @options.statsSeconds.bind 'change', this.renderIfSelected
    @options.statsSeconds.bind 'reset', this.renderIfSelected
    @options.statsMinutes.bind 'reset', this.renderIfSelected
    @options.statsHours.bind   'reset', this.renderIfSelected
    @options.statsDays.bind    'reset', this.renderIfSelected
    this.render()

  render: =>
    if MSVStats.period.get('type')?
      $(@el).data().spinner.stop()

      @mdData = MSVStats.period.stats().mdData()
      @site   = MSVStats.site
      $(@el).html(this.template(mdData: @mdData, site: @site))

      return this
    else
      $(@el).empty()
      $(@el).spin(spinOptions)
      return this

  renderIfSelected: (stats) =>
    this.render() if MSVStats.period.get('type') == stats.periodType()

