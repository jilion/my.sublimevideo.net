class MSVStats.Views.PeriodSelectorSecondsView extends Backbone.View

  initialize: () ->
    @el = $('#period_selectors .seconds')
    _.bindAll(this, 'render')
    @options.period.bind('change', this.render)
    @options.statsSeconds.bind('change', this.render)
    @options.statsSeconds.bind('reset', this.render)
    @el.bind 'click', -> 
      MSVStats.period.setPeriod(type: 'seconds')

  render: ->
    if this.isSelected() then @el.addClass('selected') else @el.removeClass('selected')
    $('#period_seconds_vv_total').html(Highcharts.numberFormat(@options.statsSeconds.vvTotal(), 0))
    this.renderSparkline()
    return this
    
  renderSparkline: ->
    $('#period_seconds_sparkline').sparkline @options.statsSeconds.pluck('vv'),
      width: '100%'
      height: '50px'
      lineColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      fillColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      
  isSelected: ->
    @options.period.get('type') == 'seconds'
