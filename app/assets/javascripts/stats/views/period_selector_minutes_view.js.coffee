class MSVStats.Views.PeriodSelectorMinutesView extends Backbone.View
  template: JST['stats/templates/_period_selector']

  initialize: () ->
    @options.period.bind 'change', this.render
    @options.statsMinutes.bind 'reset', this.render
    $(@el).bind 'click', this.select
    this.render()

  render: =>
    $(@el).html(this.template(site: MSVStats.site, period: 'last_60_minutes'))
    $(@el).find('span.title').html('last 60 minutes')
    unless MSVStats.site.isInFreePlan()
      if @options.statsMinutes.isShowable()
        $(@el).find('.content').show()
        $(@el).find('.spin').remove()
      else
        $(@el).find('.content').hide()
        $(@el).find('.spin').spin(spinOptions)
    if this.isSelected() then $(@el).addClass('selected') else $(@el).removeClass('selected')
    vvTotal = @options.statsMinutes.vvTotal()
    $(@el).find('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()
    return this

  renderSparkline: ->
    MSVStats.chartsHelper.sparkline $(@el).find('.sparkline'), @options.statsMinutes.pluck('vv'),
      width:    '100%'
      height:   '42px'
      click:    this.select
      selected: this.isSelected()

  select: =>
    if MSVStats.site.isInFreePlan()
      window.location.href = $(@el).find('a')[0].href
    else
      MSVStats.period.setPeriod(type: 'minutes')

  isSelected: ->  @options.period.isMinutes()
