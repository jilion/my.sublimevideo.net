class MSVStats.Views.TimeRangeTitleView extends Backbone.View
  template: JST['stats/templates/time_range_title']

  initialize: ->
    this._listenToModelsEvents()
    this.render()

  events: ->
    'click': '_toggleDatePicker'

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
    $('#time_range_title').removeClass('editable')
    @$el.html(this.template(period: @options.period))

    if @options.period.get('type')?
      this.$('.content').show()
      @$el.data().spinner.stop()
    else
      this.$('.content').hide()
      @$el.spin(spinOptions)
    $('#time_range_title').addClass('editable')

    this

  renderIfSelected: (stats) =>
    if MSVStats.period.get('type') == stats.periodType()
      this.render()

  #
  # PRIVATE
  #
  _toggleDatePicker: (event) ->
    event.stopPropagation()
    MSVStats.datePickersView.render()
