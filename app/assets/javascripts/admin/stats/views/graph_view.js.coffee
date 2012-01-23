class SVStats.Views.GraphView extends Backbone.View

  initialize: ->
    _.each @collection, (stat) => stat.bind 'change', this.render

  render: =>
    SVStats.statsRouter.storeCurrentExtremes()
    $(@el).resizable('destroy')
    unless _.isEmpty(@collection)
      SVStats.chartsHelper.chart(@collection)

      $(@el).resizable
        minWidth: 500
        minHeight: 350
        helper: "ui-resizable-helper"
        stop: (event, ui) =>
          SVStats.statsRouter.storeCurrentExtremes()
          this.render()

    this
