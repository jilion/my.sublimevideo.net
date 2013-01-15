class MSVStats.Views.PeriodSelectorHoursView extends Backbone.View
  template: JST['stats/templates/period_selector']

  initialize: () ->
    @options.period.bind 'change', this.render
    @options.statsHours.bind 'reset', this.render
    $(@el).bind 'click', this.select
    this.render()

  render: =>
    $(@el).html(this.template(period: 'last_24_hours'))
    $(@el).find('span.title').html('last 24 hours')
    if @options.statsHours.isShowable()
      $(@el).find('.content').show()
      $(@el).find('.spin').remove()
    else
      $(@el).find('.content').hide()
      $(@el).find('.spin').spin(spinOptions)
    if this.isSelected() then $(@el).addClass('selected') else $(@el).removeClass('selected')
    vvTotal = @options.statsHours.vvTotal()
    $(@el).find('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()
    return this

  renderSparkline: ->
    MSVStats.chartsHelper.sparkline $(@el).find('.sparkline'), @options.statsHours.pluck('vv'),
      width:    '100%'
      height:   '42px'
      click:    this.select
      selected: this.isSelected()

  select: => MSVStats.period.setPeriod(type: 'hours')

  isSelected: -> @options.period.isHours()
