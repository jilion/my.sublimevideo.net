class MSVStats.Views.BPView extends Backbone.View
  template: JST['stats/templates/_bp']

  initialize: () ->
    @options.period.bind 'change', this.render
    @options.statsSeconds.bind 'change', this.renderIfSelected
    @options.statsSeconds.bind 'reset', this.renderIfSelected
    @options.statsMinutes.bind 'reset', this.renderIfSelected
    @options.statsHours.bind   'reset', this.renderIfSelected
    @options.statsDays.bind    'reset', this.renderIfSelected
    this.render()

  render: =>    
    if MSVStats.period.get('type')?
      $(@el).show()
      $('#bp').data().spinner.stop()
      
      @bpData = MSVStats.period.stats().bpData()
      $(@el).html(this.template(bpData: @bpData))
      
      return this
    else
      $(@el).hide()
      $('#bp').spin()
      return this
      
  renderIfSelected: (stats) =>
    this.render() if MSVStats.period.get('type') == stats.periodType()

