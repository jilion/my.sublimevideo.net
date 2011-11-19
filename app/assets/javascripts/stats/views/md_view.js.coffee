class MSVStats.Views.MDView extends Backbone.View
  template: JST['stats/templates/_md']

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
      $(@el).data().spinner.stop()
      
      @mdData = MSVStats.period.stats().mdData()
      $(@el).html(this.template(mdData: @mdData))
      
      return this
    else
      $(@el).empty()
      $(@el).spin(color:'#1e3966',lines:10,length:5,width:4,radius:8,speed:1,trail:60,shadow:false)
      return this
      
  renderIfSelected: (stats) =>
    this.render() if MSVStats.period.get('type') == stats.periodType()

