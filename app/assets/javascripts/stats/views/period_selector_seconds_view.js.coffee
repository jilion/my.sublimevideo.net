class MSVStats.Views.PeriodSelectorSecondsView extends Backbone.View
  template: JST['stats/templates/_period_selector']
  
  initialize: () ->
    _.bindAll(this, 'render')
    @options.period.bind('change', this.render)
    @options.statsSeconds.bind('change', this.render)
    @options.statsSeconds.bind('reset', this.render)
    $(@el).bind 'click', -> 
      if MSVStats.statsSeconds.isShowable()
        MSVStats.period.setPeriod type: 'seconds', startIndex: 0, endIndex: 59
        setTimeout MSVStats.videos.fetchOldSeconds, 3000
    this.render()

  render: ->
    $(@el).html(this.template(site: MSVStats.sites.selectedSite))
    $(@el).find('span.title').html('last 60 seconds')    
    unless MSVStats.sites.selectedSite.inFreePlan()
      if @options.statsSeconds.isShowable()
        $(@el).find('.content').show()
        $(@el).data().spinner.stop()
      else
        $(@el).find('.content').hide()
        $(@el).spin()
      if this.isSelected() then $(@el).addClass('selected') else $(@el).removeClass('selected')
      vvTotal = @options.statsSeconds.vvTotal(0, 59)
      $(@el).find('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
      this.renderSparkline() 
    return this
    
  renderSparkline: ->
    $(@el).find('.sparkline').sparkline @options.statsSeconds.customPluck('vv', 0, 59),
      width: '100%'
      height: '50px'
      lineColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      fillColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      
  isSelected: ->
    @options.period.isSeconds()
