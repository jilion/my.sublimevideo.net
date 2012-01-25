class AdminSublimeVideo.Views.GraphView extends Backbone.View
  initialize: ->
    _.each @collection, (stat) => stat.bind 'change', this.render
    @options.period.bind 'change', this.render

  render: =>
    $(@el).resizable('destroy')

    unless _.isEmpty(@collection)
      AdminSublimeVideo.chartsHelper.chart(@collection)

      $(@el).resizable
        minWidth: 500
        minHeight: 350
        helper: "ui-resizable-helper"
        stop: (event, ui) =>
          this.render()

    this
