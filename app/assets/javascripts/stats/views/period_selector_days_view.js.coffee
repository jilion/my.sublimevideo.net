class MSVStats.Views.PeriodSelectorDaysView extends Backbone.View

  initialize: () ->
    @el = $('#period_selectors .days')
    _.bindAll(this, 'render')
    @options.period.bind('change', this.render)
    @options.statsDays.bind('reset', this.render)
    @el.bind 'click', -> 
      $('#vv').spin()
      setTimeout (-> MSVStats.period.setPeriod(type: 'days')), 100

  render: ->
    if this.isSelected() then @el.addClass('selected') else @el.removeClass('selected')
    vvTotal = @options.statsDays.vvTotal()
    $('#period_days_vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()
    return this

  renderSparkline: ->
    $('#period_days_sparkline').sparkline @options.statsDays.pluck('vv'),
      width: '100%'
      height: '50px'
      lineColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      fillColor: if this.isSelected() then '#0046ff' else '#00b1ff'

  isSelected: ->
    @options.period.get('type') == 'days' && @options.period.get('startIndex') == 0 && @options.period.get('endIndex') == -1

