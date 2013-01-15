class MSVStats.Views.PeriodSelectorSecondsView extends Backbone.View
  template: JST['stats/templates/period_selector']

  initialize: () ->
    @options.period.bind 'change', this.render
    @options.statsSeconds.bind 'change', this.render
    @options.statsSeconds.bind 'reset', this.render
    @options.pusher.connection.bind 'failed', this.render
    $(@el).bind 'click', this.select
    this.render()

  render: =>
    $(@el).html(this.template(pusherState: @options.pusher.connection.state, site: MSVStats.site, period: 'last_60_seconds'))

    if @options.statsSeconds.isShowable()
      $(@el).find('.content').show()
      $(@el).find('.spin').remove()
    else if @options.pusher.connection.state != 'failed'
      $(@el).find('.content').hide()
      $(@el).find('.spin').spin(spinOptions)

    if this.isSelected() then $(@el).addClass('selected') else $(@el).removeClass('selected')

    vvTotal = @options.statsSeconds.vvTotal(0, 59)
    $(@el).find('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()
    $(@el).find('span.title').html('last 60 seconds')

    this

  renderSparkline: ->
    MSVStats.chartsHelper.sparkline $(@el).find('.sparkline'), @options.statsSeconds.customPluck('vv', 0, 59),
      width:    '100%'
      height:   '42px'
      click:    this.select
      selected: this.isSelected()

  select: =>
    if MSVStats.statsSeconds.isShowable()
      MSVStats.period.setPeriod type: 'seconds', startIndex: 0, endIndex: 59

  isSelected: -> @options.period.isSeconds()
