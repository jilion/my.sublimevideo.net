class MSVStats.Views.PeriodSelectorMinutesView extends Backbone.View

  initialize: () ->
    @el = $('#period_selectors .minutes')
    _.bindAll(this, 'render')
    @options.period.bind('change', this.render)
    @options.statsMinutes.bind('reset', this.render)
    @el.bind 'click', ->
      MSVStats.period.setPeriod(type: 'minutes')

  render: ->
    if this.isSelected() then @el.addClass('selected') else @el.removeClass('selected')
    $('#period_minutes_vv_total').html(@options.statsMinutes.vvTotal())
    this.renderSparkline()
    return this
    
  renderSparkline: ->
    $('#period_minutes_sparkline').sparkline @options.statsMinutes.pluck('vv'),
      width: '100%'
      height: '50px'
      lineColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      fillColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      
  isSelected: ->
    @options.period.isSelected('minutes')
