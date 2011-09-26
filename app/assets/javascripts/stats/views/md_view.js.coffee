class MSVStats.Views.MDView extends Backbone.View
  template: JST['stats/templates/_md']

  initialize: () ->
    _.bindAll this, 'render', 'renderIfSelected'
    @options.period.bind 'change', this.render
    @options.statsMinutes.bind 'reset', this.renderIfSelected
    @options.statsHours.bind   'reset', this.renderIfSelected
    @options.statsDays.bind    'reset', this.renderIfSelected
    $('#md_content').html(this.render().el)

  render: ->    
    if MSVStats.period.get('type')?
      $('#md_content').show()
      $('#md').data().spinner.stop()
      
      @mdData = MSVStats.period.stats().mdData()
      $(this.el).html(this.template(mdData: @mdData))
      
      return this
    else
      $('#md_content').hide()
      $('#md').spin()
      return this
      
  renderIfSelected: (stats) ->
    this.render() if MSVStats.period.get('type') == stats.periodType()

