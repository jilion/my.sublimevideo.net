class MSVStats.Views.DatesRangeTitleView extends Backbone.View
  template: JST['stats/templates/_dates_range_title']

  initialize: ->
    _.bindAll this, 'render', 'renderIfSelected'
    @options.period.bind 'change', this.render
    @options.statsSeconds.bind 'change', this.renderIfSelected
    @options.statsSeconds.bind 'reset', this.renderIfSelected
    @options.statsMinutes.bind 'reset', this.renderIfSelected
    @options.statsHours.bind   'reset', this.renderIfSelected
    @options.statsDays.bind    'reset', this.renderIfSelected
    $('#dates_range_title').html(this.render().el)

  render: ->
    $(this.el).html(this.template(period: @options.period))
    return this

  renderIfSelected: (stats) ->
    this.render() if MSVStats.period.get('type') == stats.periodType()