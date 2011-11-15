class MSVStats.Views.PeriodSelectorHoursView extends Backbone.View
  template: JST['stats/templates/_period_selector']

  initialize: () ->
    @options.period.bind 'change', this.render
    @options.statsHours.bind 'reset', this.render
    $(@el).bind 'click', this.select
    this.render()

  render: =>
    $(@el).html(this.template())
    $(@el).find('span.title').html('last 24 hours')
    if this.isSelected() then $(@el).addClass('selected') else $(@el).removeClass('selected')
    vvTotal = @options.statsHours.vvTotal()
    $(@el).find('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()
    return this
     
  renderSparkline: ->
    MSVStats.chartsHelper.sparkline $(@el).find('.sparkline'), @options.statsHours.pluck('vv'),
      width:    '100%'
      height:   '50px'
      click:    this.select
      selected: this.isSelected()

  select: => MSVStats.period.setPeriod(type: 'hours')

  isSelected: ->
    @options.period.isHours()
