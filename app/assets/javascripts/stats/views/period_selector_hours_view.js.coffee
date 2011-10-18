class MSVStats.Views.PeriodSelectorHoursView extends Backbone.View
  template: JST['stats/templates/_period_selector']
  
  initialize: () ->
    _.bindAll(this, 'render')
    @options.period.bind('change', this.render)
    @options.statsHours.bind('reset', this.render)
    $(@el).bind 'click', -> 
      MSVStats.period.setPeriod(type: 'hours')
    this.render()

  render: ->
    $(@el).html(this.template())
    $(@el).find('span.title').html('last 24 hours')
    if this.isSelected() then $(@el).addClass('selected') else $(@el).removeClass('selected')
    vvTotal = @options.statsHours.vvTotal()
    $(@el).find('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()
    return this

  renderSparkline: ->
    $(@el).find('.sparkline').sparkline @options.statsHours.pluck('vv'),
      width: '100%'
      height: '50px'
      lineColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      fillColor: if this.isSelected() then '#0046ff' else '#00b1ff'

  isSelected: ->
    @options.period.get('type') == 'hours'
