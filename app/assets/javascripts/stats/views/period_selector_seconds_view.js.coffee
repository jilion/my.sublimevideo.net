class MSVStats.Views.PeriodSelectorSecondsView extends Backbone.View
  template: JST['stats/templates/period_selector']

  initialize: ->
    this._listenToModelsEvents()
    this.render()

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    this.listenTo(@options.period, 'change', this.render)
    this.listenTo(@options.statsSeconds, 'change reset', this.render)
    @options.pusher.connection.bind 'failed', this.render
    @$el.on('click', this.select)

  render: =>
    @$el.html(this.template(pusherState: @options.pusher.connection.state, site: MSVStats.site, period: 'last_60_seconds'))

    if @options.statsSeconds.isShowable()
      this.$('.content').show()
      this.$('.spin').remove()
    else if @options.pusher.connection.state != 'failed'
      this.$('.content').hide()
      this.$('.spin').spin(spinOptions)

    if this.isSelected()
      @$el.addClass('selected')
    else
      @$el.removeClass('selected')

    vvTotal = @options.statsSeconds.vvTotal(0, 59)
    this.$('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()
    this.$('span.title').html('last 60 seconds')

    this

  renderSparkline: ->
    MSVStats.chartsHelper.sparkline(this.$('.sparkline'), @options.statsSeconds.customPluck('vv', 0, 59),
      width:    '100%'
      height:   '42px'
      click:    this.select
      selected: this.isSelected())

  select: =>
    if MSVStats.statsSeconds.isShowable()
      MSVStats.period.setPeriod(type: 'seconds', startIndex: 0, endIndex: 59)

  isSelected: ->
    @options.period.isSeconds()
