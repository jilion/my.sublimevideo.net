class MSVStats.Views.PeriodSelectorDaysView extends Backbone.View

  initialize: () ->
    @el = $('#period_selectors .days')
    _.bindAll(this, 'render')
    @options.period.bind('change', this.render)
    @options.statsDays.bind('reset', this.render)
    @el.bind('click', _.bind(this.select, this))

  render: ->
    if this.isSelected() then @el.addClass('selected') else @el.removeClass('selected')
    $('#period_days_vv_total').html(Highcharts.numberFormat(@options.statsDays.vvTotal(this.dateRange()), 0))
    this.renderSparkline()
    return this

  renderSparkline: ->
    $('#period_days_sparkline').sparkline @options.statsDays.customPluck('vv', -30),
      width: '100%'
      height: '50px'
      lineColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      fillColor: if this.isSelected() then '#0046ff' else '#00b1ff'

  select: ->
    @options.period.setPeriod type: 'days', startIndex: -30, endIndex: -1

  isSelected: ->
    @options.period.get('type') == 'days' && @options.period.get('startIndex') == -30 && @options.period.get('endIndex') == -1

  dateRange: ->
    if MSVStats.statsDays.isEmpty()
      [null, null]
    else
      [MSVStats.statsDays.at(MSVStats.statsDays.length - 30).time(), MSVStats.statsDays.last().time()]

