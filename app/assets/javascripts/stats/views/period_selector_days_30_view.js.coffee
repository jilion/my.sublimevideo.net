class MSVStats.Views.PeriodSelectorDays30View extends Backbone.View
  template: JST['stats/templates/period_selector']

  initialize: ->
    this._listenToModelsEvents()
    this.render()

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    this.listenTo(@options.period, 'change', this.render)
    this.listenTo(@options.statsDays, 'reset', this.render)
    @$el.on('click', this.select)

  render: =>
    @$el.html(this.template(site: MSVStats.site, period: 'last_30_days'))
    this.$('span.title').html('last 30 days')

    if @options.statsDays.isShowable()
      this.$('.content').show()
      this.$('.spin').remove()
    else
      this.$('.content').hide()
      this.$('.spin').spin(spinOptions)

    if this.isSelected()
      @$el.addClass('selected')
    else
      @$el.removeClass('selected')

    vvTotal = @options.statsDays.vvTotal(-30, -1)
    this.$('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()

    this

  renderSparkline: ->
    MSVStats.chartsHelper.sparkline(this.$('.sparkline'), @options.statsDays.customPluck('vv', -30, -1),
      width:    '100%'
      height:   '42px'
      click:    this.select
      selected: this.isSelected())

  select: =>
    MSVStats.period.setPeriod(type: 'days', startIndex: -30, endIndex: -1)

  isSelected: ->
    @options.period.isSelected('days', -30, -1)
