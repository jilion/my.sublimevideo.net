class MSVStats.Views.VVView extends Backbone.View
  template: JST['stats/templates/vv_chart_legend']

  initialize: ->
    this._listenToModelsEvents()
    this.render()

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    this.listenTo(@options.period, 'change', this.render)
    this.listenTo(@options.statsSeconds, 'change reset', this.renderIfSelected)
    this.listenTo(@options.statsMinutes, 'reset', this.renderIfSelected)
    this.listenTo(@options.statsHours, 'reset', this.renderIfSelected)
    this.listenTo(@options.statsDays, 'reset', this.renderIfSelected)

  render: =>
    if MSVStats.period.get('type')?
      $('#plays_and_loads_graph').show()
      $('#plays_and_loads').data().spinner.stop()
      @stats = MSVStats.period.stats()
      @$el.html(this.template(stats: @stats))
      MSVStats.chartsHelper.vvChart(@stats)
    else
      $('#plays_and_loads_graph').hide()
      $('#plays_and_loads').spin(spinOptions)
      @$el.html(this.template())

    this

  renderIfSelected: (stats) =>
    if MSVStats.period.get('type') == stats.periodType()
      this.render()
