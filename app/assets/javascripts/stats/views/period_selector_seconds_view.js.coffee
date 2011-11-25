class MSVStats.Views.PeriodSelectorSecondsView extends Backbone.View
  template: JST['stats/templates/_period_selector']
  
  initialize: () ->
    @options.period.bind 'change', this.render
    @options.statsSeconds.bind 'change', this.render
    @options.statsSeconds.bind 'reset', this.render
    $(@el).bind 'click', this.select
    this.render()

  render: =>
    if (selectedSite = MSVStats.sites.selectedSite)?
      $(@el).html(this.template(site: selectedSite))
      $(@el).find('span.title').html('last 60 seconds')
      unless selectedSite.isInFreePlan()
        if @options.statsSeconds.isShowable()
          $(@el).find('.content').show()
          $(@el).data().spinner.stop()
        else
          $(@el).find('.content').hide()
          $(@el).spin(spinOptions)
        if this.isSelected() then $(@el).addClass('selected') else $(@el).removeClass('selected')
        vvTotal = @options.statsSeconds.vvTotal(0, 59)
        $(@el).find('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
        this.renderSparkline() 
    return this
      
  renderSparkline: ->
    MSVStats.chartsHelper.sparkline $(@el).find('.sparkline'), @options.statsSeconds.customPluck('vv', 0, 59),
      width:    '100%'
      height:   '42px'
      click:    this.select
      selected: this.isSelected()

  select: =>
    if MSVStats.sites.selectedSite.isInFreePlan()
      window.location.href = $(@el).find('a')[0].href
    if MSVStats.statsSeconds.isShowable()
      MSVStats.period.setPeriod type: 'seconds', startIndex: 0, endIndex: 59

  isSelected: ->
    @options.period.isSeconds()
