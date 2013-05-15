class MSVStats.Views.PeriodSelectorMinutesView extends Backbone.View
  template: JST['stats/templates/period_selector']

  initialize: ->
    this._listenToModelsEvents()
    this.render()

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    this.listenTo(@options.period, 'change', this.render)
    this.listenTo(@options.statsMinutes, 'reset', this.render)
    @$el.on('click', this.select)

  render: =>
    @$el.html(this.template(site: MSVStats.site, period: 'last_60_minutes'))
    this.$('span.title').html('last 60 minutes')

    if @options.statsMinutes.isShowable()
      this.$('.content').show()
      this.$('.spin').remove()
    else
      this.$('.content').hide()
      this.$('.spin').spin(spinOptions)

    if this.isSelected()
      @$el.addClass('selected')
    else
      @$el.removeClass('selected')

    vvTotal = @options.statsMinutes.vvTotal()
    this.$('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()

    this

  renderSparkline: ->
    MSVStats.chartsHelper.sparkline(this.$('.sparkline'), @options.statsMinutes.pluck('vv'),
      width:    '100%'
      height:   '42px'
      click:    this.select
      selected: this.isSelected())

  select: =>
    MSVStats.period.setPeriod(type: 'minutes')

  isSelected: ->
    @options.period.isMinutes()
