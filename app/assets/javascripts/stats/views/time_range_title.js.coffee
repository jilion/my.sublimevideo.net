class MSVStats.Views.TimeRangeTitleView extends Backbone.View
  template: JST['stats/templates/_time_range_title']

  events:
    'click': 'toggleDatePicker'

  initialize: ->
    @options.period.bind       'change', this.render
    @options.statsSeconds.bind 'change', this.renderIfSelected
    @options.statsSeconds.bind 'reset',  this.renderIfSelected
    @options.statsMinutes.bind 'reset',  this.renderIfSelected
    @options.statsHours.bind   'reset',  this.renderIfSelected
    @options.statsDays.bind    'reset',  this.renderIfSelected
    this.render()

  render: =>
    $('#time_range_title').removeClass('editable')
    $(@el).html(this.template(period: @options.period))
    if @options.period.get('type')?
      $(@el).find('.content').show()
      $(@el).data().spinner.stop()
    else
      $(@el).find('.content').hide()
      $(@el).spin(spinOptions)
    unless MSVStats.site.isInFreePlan()
      $('#time_range_title').addClass('editable')
    return this

  renderIfSelected: (stats) =>
    this.render() if MSVStats.period.get('type') == stats.periodType()

  toggleDatePicker: (event) ->
    unless MSVStats.site.isInFreePlan()
      event.stopPropagation()
      MSVStats.datePickersView.render()
