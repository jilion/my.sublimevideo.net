class MSVStats.Views.BPView extends Backbone.View
  template: JST['stats/templates/bp']

  initialize: ->
    @showAll = false
    this._listenToModelsEvents()
    this.render()

  events: ->
    'click a#show_all':  '_showAll'
    'click a#show_less': '_showLess'

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    this.listenTo(@options.period, 'change', this.render)
    this.listenTo(@options.statsSeconds, 'change reset', this.renderIfSelected)
    this.listenTo(@options.statsMinutes, 'reset', this.renderIfSelected)
    this.listenTo(@options.statsHours, 'reset', this.renderIfSelected)
    this.listenTo(@options.statsDays, 'reset', this.renderIfSelected)

  render: =>
    if MSVStats.period.get('type')?
      @$el.data().spinner.stop()

      @bpData = MSVStats.period.stats().bpData()
      bps     = @bpData.toArray()
      @total  = bps.length
      @limit  = 7
      @bps    = if @showAll then bps else _.first(bps, @limit)
      @site   = MSVStats.site
      @$el.html(this.template(bpData: @bpData, bps: @bps, total: @total, showAll: @showAll, limit: @limit, site: @site))
    else
      @$el.empty()
      @$el.spin(spinOptions)

    this

  renderIfSelected: (stats) =>
    if MSVStats.period.get('type') is stats.periodType()
      this.render()

  #
  # PRIVATE
  #
  _showAll: ->
    @showAll = true
    this.render()

    false

  _showLess: ->
    @showAll = false
    this.render()

    false
