class MSVStats.Views.VVView extends Backbone.View
  template: JST['stats/templates/vv_chart_legend']

  initialize: ->
    @options.period.bind 'change', this.render
    @options.statsSeconds.bind 'change', this.renderIfSelected
    @options.statsSeconds.bind 'reset',  this.renderIfSelected
    @options.statsMinutes.bind 'reset',  this.renderIfSelected
    @options.statsHours.bind   'reset',  this.renderIfSelected
    @options.statsDays.bind    'reset',  this.renderIfSelected
    this.render()

  render: =>
    if MSVStats.period.get('type')?
      $('#vv_content').show()
      $('#vv').data().spinner.stop()
      @stats = MSVStats.period.stats()
      $(@el).html(this.template(stats: @stats))
      MSVStats.chartsHelper.vvChart(@stats)
      return this
    else
      $('#vv_content').hide()
      $('#vv').spin(spinOptions)
      $(@el).html(this.template())
      return this

  renderIfSelected: (stats) =>
    this.render() if MSVStats.period.get('type') == stats.periodType()
