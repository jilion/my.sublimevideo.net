class AdminSublimeVideo.Views.GraphView extends Backbone.View
  initialize: ->
    _.each @collection, (stat) => stat.bind 'change', this.render
    @options.period.bind 'change', this.render

  render: =>
    if _.isEmpty(@collection) or _.all(@collection, (stats) -> stats.selected.length is 0)
      $(@el).html('')
    else
      $(@el).resizable('destroy')
      currentScroll = $(window).scrollTop()

      AdminSublimeVideo.chartsHelper.chart(@collection)

      $(@el).resizable
        minWidth: 500
        minHeight: 350
        helper: "ui-resizable-helper"
        stop: (event, ui) =>
          this.render()

      setTimeout((=> $(window).scrollTop(currentScroll)), 1)

    this
