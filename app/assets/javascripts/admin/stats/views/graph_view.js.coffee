class SVStats.Views.GraphView extends Backbone.View

  initialize: ->
    @options.usersStats.bind 'reset',  this.render
    @options.usersStats.bind 'change', this.render
    this.render()

  render: =>
    if @options.usersStats.isEmpty()
      console.log "no usersStats ? #{@options.usersStats}"
    else
      SVStats.chartsHelper.chart([@options.usersStats])

    this
