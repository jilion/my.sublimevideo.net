class MSVStats.Views.PeriodSelectorSecondsView extends Backbone.View

  initialize: () ->
    @el = $('#period_selectors .seconds')
    _.bindAll(this, 'render')
    @options.period.bind('change', this.render)
    @options.statsSeconds.bind('change', this.render)
    @options.statsSeconds.bind('reset', this.render)
    @el.bind 'click', -> 
      MSVStats.period.setPeriod type: 'seconds', startIndex: 0, endIndex: 59

  render: ->
    if @options.statsSeconds.length >= 60
      $('#period_seconds_content').show()
      @el.data().spinner.stop()
    else
      $('#period_seconds_content').hide()
      @el.spin()
    
    if this.isSelected() then @el.addClass('selected') else @el.removeClass('selected')
    vvTotal = @options.statsSeconds.vvTotal(0, 59)
    $('#period_seconds_vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()
    
    return this
    
  renderSparkline: ->
    $('#period_seconds_sparkline').sparkline @options.statsSeconds.customPluck('vv', 0, 59),
      width: '100%'
      height: '50px'
      lineColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      fillColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      
  isSelected: ->
    @options.period.get('type') == 'seconds'
