class MSVStats.Views.DatesRangeTitleView extends Backbone.View
  template: JST['stats/templates/_dates_range_title']

  events:
    'click': 'toggleDatePicker'

  initialize: ->
    @options.period.bind 'change', this.render
    @options.statsSeconds.bind 'change', this.renderIfSelected
    @options.statsSeconds.bind 'reset', this.renderIfSelected
    @options.statsMinutes.bind 'reset', this.renderIfSelected
    @options.statsHours.bind   'reset', this.renderIfSelected
    @options.statsDays.bind    'reset', this.renderIfSelected
    this.render()

  render: =>
    $(@el).html(this.template(period: @options.period))
    if MSVStats.sites.selectedSite.inFreePlan()
      $('#dates_range_title').removeClass('editable')
      $('div.stats').addClass('free')
    else
      $('#dates_range_title').addClass('editable')
    return this

  renderIfSelected: (stats) =>
    this.render() if MSVStats.period.get('type') == stats.periodType()

  toggleDatePicker: (event) ->
    unless MSVStats.sites.selectedSite.inFreePlan()
      event.stopPropagation()
      MSVStats.datePickersView.render()
