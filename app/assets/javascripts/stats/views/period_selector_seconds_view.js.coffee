class MSVStats.Views.PeriodSelectorSecondsView extends Backbone.View
  template: JST['stats/templates/_period_selector']
  
  initialize: () ->
    @options.period.bind 'change', this.render
    @options.statsSeconds.bind 'change', this.render
    @options.statsSeconds.bind 'reset', this.render
    $(@el).bind 'click', this.select
    this.render()

  render: =>
    $(@el).html(this.template(site: MSVStats.sites.selectedSite))
    $(@el).find('span.title').html('last 60 seconds')
    unless MSVStats.sites.selectedSite.inFreePlan()
      if @options.statsSeconds.isShowable()
        $(@el).find('.content').show()
        $(@el).data().spinner.stop()
      else
        $(@el).find('.content').hide()
        $(@el).spin(color:'#d5e5ff',lines:10,length:5,width:4,radius:8,speed:1,trail:60,shadow: false)
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
    if MSVStats.statsSeconds.isShowable()
      MSVStats.period.setPeriod type: 'seconds', startIndex: 0, endIndex: 59

  isSelected: ->
    @options.period.isSeconds()
