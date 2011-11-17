class MSVStats.Views.PeriodSelectorDays365View extends Backbone.View
  template: JST['stats/templates/_period_selector']

  initialize: () ->
    @options.period.bind 'change', this.render
    @options.statsDays.bind 'reset', this.render
    $(@el).bind 'click', this.select
    this.render()

  render: =>
    $(@el).html(this.template(site: MSVStats.sites.selectedSite))
    $(@el).find('span.title').html('last 365 days')
    unless MSVStats.sites.selectedSite.inFreePlan()
      if this.isSelected() then $(@el).addClass('selected') else $(@el).removeClass('selected')
      vvTotal = @options.statsDays.vvTotal(-365, -1)
      $(@el).find('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
      this.renderSparkline()
    return this

  renderSparkline: ->
    MSVStats.chartsHelper.sparkline $(@el).find('.sparkline'), @options.statsDays.customPluck('vv', -365, -1),
      width:    '100%'
      height:   '42px'
      click:   this.select
      selected: this.isSelected()

  select: =>
    unless MSVStats.sites.selectedSite.inFreePlan()
      # $('#vv').spin()
      # setTimeout (-> MSVStats.period.setPeriod(type: 'days', startIndex: -365, endIndex: -1)), 50
      MSVStats.period.setPeriod(type: 'days', startIndex: -365, endIndex: -1)

  isSelected: ->
    @options.period.isSelected('days', -365, -1)

