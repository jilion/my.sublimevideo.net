class MSVStats.Views.BPView extends Backbone.View
  template: JST['stats/templates/_bp']

  initialize: () ->
    _.bindAll this, 'render', 'renderIfSelected'
    @options.period.bind 'change', this.render
    @options.statsSeconds.bind 'change', this.renderIfSelected
    @options.statsSeconds.bind 'reset', this.renderIfSelected
    @options.statsMinutes.bind 'reset', this.renderIfSelected
    @options.statsHours.bind   'reset', this.renderIfSelected
    @options.statsDays.bind    'reset', this.renderIfSelected
    $('#bp_content').html(this.render().el)

  render: ->    
    if MSVStats.period.get('type')?
      $('#bp_content').show()
      $('#bp').data().spinner.stop()
      
      @bpData = MSVStats.period.stats().bpData()
      $(this.el).html(this.template(bpData: @bpData))
      
      return this
    else
      $('#bp_content').hide()
      $('#bp').spin()
      return this
      
  renderIfSelected: (stats) ->
    this.render() if MSVStats.period.get('type') == stats.periodType()

