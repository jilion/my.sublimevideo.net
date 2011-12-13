class SVStats.Views.GraphView extends Backbone.View

  initialize: ->
    _.each @collection, (stat) => stat.bind 'change', this.render

  render: =>
    if _.isEmpty(@collection)
      console.log "no stats !"
    else
      SVStats.chartsHelper.chart(@collection)

    this
