class MSVStats.Views.BPView extends Backbone.View
  template: JST['stats/templates/bp']

  events: ->
    'click a#show_all':  '_showAll'
    'click a#show_less': '_showLess'

  initialize: ->
    @showAll = false
    @options.period.bind       'change', this.render
    @options.statsSeconds.bind 'change', this.renderIfSelected
    @options.statsSeconds.bind 'reset', this.renderIfSelected
    @options.statsMinutes.bind 'reset', this.renderIfSelected
    @options.statsHours.bind   'reset', this.renderIfSelected
    @options.statsDays.bind    'reset', this.renderIfSelected
    this.render()

  render: =>
    if MSVStats.period.get('type')?
      $(@el).data().spinner.stop()

      @bpData = MSVStats.period.stats().bpData()
      bps     = @bpData.toArray()
      @total  = bps.length
      @limit  = 7
      @bps    = if @showAll then bps else _.first(bps, @limit)
      @site   = MSVStats.site
      $(@el).html(this.template(bpData: @bpData, bps: @bps, total: @total, showAll: @showAll, limit: @limit, site: @site))
    else
      $(@el).empty()
      $(@el).spin(spinOptions)

    this

  renderIfSelected: (stats) =>
    this.render() if MSVStats.period.get('type') == stats.periodType()

  _showAll: ->
    @showAll = true
    this.render()
    false

  _showLess: ->
    @showAll = false
    this.render()
    false
