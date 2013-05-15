class MSVStats.Views.MDView extends Backbone.View
  template: JST['stats/templates/md']

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
      @$el.data().spinner.stop()

      @mdData = MSVStats.period.stats().mdData()
      @site   = MSVStats.site
      @$el.html(this.template(mdData: @mdData, site: @site))
    else
      @$el.empty()
      @$el.spin(spinOptions)

    this

  renderIfSelected: (stats) =>
    if MSVStats.period.get('type') is stats.periodType()
      this.render()
