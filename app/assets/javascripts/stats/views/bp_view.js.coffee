class MSVStats.Views.BPView extends Backbone.View
  template: JST['stats/templates/_bp']

  events:
    'click a#show_all':  'showAll'
    'click a#show_less': 'showLess'

  initialize: () ->
    @showAll = false
    @options.period.bind 'change', this.render
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
      $(@el).html(this.template(bpData: @bpData, bps: @bps, total: @total, showAll: @showAll, limit: @limit))
      
      return this
    else
      $(@el).empty()
      $(@el).spin(color:'#1e3966',lines:10,length:5,width:4,radius:8,speed:1,trail:60,shadow:false)
      return this
      
  renderIfSelected: (stats) =>
    this.render() if MSVStats.period.get('type') == stats.periodType()

  showAll: ->
    @showAll = true
    this.render()
    false

  showLess: ->
    @showAll = false
    this.render()
    false
