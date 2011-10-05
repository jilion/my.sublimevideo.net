class MSVStats.Views.MDView extends Backbone.View
  template: JST['stats/templates/_md']

  initialize: () ->
    _.bindAll this, 'render', 'renderIfSelected'
    @options.period.bind 'change', this.render
    @options.statsSeconds.bind 'change', this.renderIfSelected
    @options.statsSeconds.bind 'reset', this.renderIfSelected
    @options.statsMinutes.bind 'reset', this.renderIfSelected
    @options.statsHours.bind   'reset', this.renderIfSelected
    @options.statsDays.bind    'reset', this.renderIfSelected
    this.render()

  render: ->    
    if MSVStats.period.get('type')?
      $(@el).show()
      $('#md').data().spinner.stop()
      
      @mdData = MSVStats.period.stats().mdData()
      $(@el).html(this.template(mdData: @mdData))
      
      return this
    else
      $(@el).hide()
      $('#md').spin()
      return this
      
  renderIfSelected: (stats) ->
    this.render() if MSVStats.period.get('type') == stats.periodType()

