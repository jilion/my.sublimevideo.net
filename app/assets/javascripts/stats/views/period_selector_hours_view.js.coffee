class MSVStats.Views.PeriodSelectorHoursView extends Backbone.View
  template: JST['stats/templates/period_selector']

  initialize: ->
    this._listenToModelsEvents()
    this.render()

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    this.listenTo(@options.period, 'change', this.render)
    this.listenTo(@options.statsHours, 'reset', this.render)
    @$el.on('click', this.select)

  render: =>
    @$el.html(this.template(period: 'last_24_hours'))
    this.$('span.title').html('last 24 hours')

    if @options.statsHours.isShowable()
      this.$('.content').show()
      this.$('.spin').remove()
    else
      this.$('.content').hide()
      this.$('.spin').spin(spinOptions)

    if this.isSelected()
      @$el.addClass('selected')
    else
      @$el.removeClass('selected')

    vvTotal = @options.statsHours.vvTotal()
    this.$('span.vv_total').html(Highcharts.numberFormat(vvTotal, 0))
    this.renderSparkline()
    
    this

  renderSparkline: ->
    MSVStats.chartsHelper.sparkline(this.$('.sparkline'), @options.statsHours.pluck('vv'),
      width:    '100%'
      height:   '42px'
      click:    this.select
      selected: this.isSelected())

  select: =>
    MSVStats.period.setPeriod(type: 'hours')

  isSelected: ->
    @options.period.isHours()
