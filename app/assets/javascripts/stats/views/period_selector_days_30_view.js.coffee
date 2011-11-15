class MSVStats.Views.PeriodSelectorDays30View extends Backbone.View
  template: JST['stats/templates/_period_selector']

  initialize: () ->
    @options.period.bind 'change', this.render
    @options.statsDays.bind 'reset', this.render
    $(@el).bind 'click', this.select
    this.render()

  render: =>
    $(@el).html(this.template(site: MSVStats.sites.selectedSite))
    $(@el).find('span.title').html('last 30 days')
    unless MSVStats.sites.selectedSite.inFreePlan()
      if this.isSelected() then $(@el).addClass('selected') else $(@el).removeClass('selected')
      vvTotal = @options.statsDays.vvTotal(-30, -1)
      $(@el).find('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
      this.renderSparkline()
    return this

  renderSparkline: ->
    MSVStats.chartsHelper.sparkline $(@el).find('.sparkline'), @options.statsDays.customPluck('vv', -30, -1),
      width:    '100%'
      height:   '50px'
      click:   this.select
      selected: this.isSelected()

  select: =>
    unless MSVStats.sites.selectedSite.inFreePlan()
      MSVStats.period.setPeriod type: 'days', startIndex: -30, endIndex: -1

  isSelected: ->
    @options.period.isSelected('days', -30, -1)

