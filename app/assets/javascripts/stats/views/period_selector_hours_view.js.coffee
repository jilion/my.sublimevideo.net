class MSVStats.Views.PeriodSelectorHoursView extends Backbone.View

  initialize: () ->
    @el = $('#period_selectors .hours')
    _.bindAll(this, 'render')
    @options.period.bind('change', this.render)
    @options.statsHours.bind('reset', this.render)
    @el.bind 'click', -> 
      MSVStats.period.setPeriod(type: 'hours')

  render: ->
    if this.isSelected() then @el.addClass('selected') else @el.removeClass('selected')
    vvTotal = @options.statsHours.vvTotal()
    $('#period_hours_vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()
    return this

  renderSparkline: ->
    $('#period_hours_sparkline').sparkline @options.statsHours.pluck('vv'),
      width: '100%'
      height: '50px'
      lineColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      fillColor: if this.isSelected() then '#0046ff' else '#00b1ff'

  isSelected: ->
    @options.period.get('type') == 'hours'
