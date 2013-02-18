class AdminSublimeVideo.Views.GraphView extends Backbone.View
  initialize: ->
    _.each @collection, (trend) => trend.bind 'change', this.render
    @options.period.bind 'change', this.render

  render: =>
    if _.isEmpty(@collection) or _.all(@collection, (trends) -> trends.selected.length is 0)
      $(@el).html('')
    else
      $(@el).resizable('destroy')
      currentScroll = $(window).scrollTop()

      AdminSublimeVideo.chartsHelper.chart(@collection)
      AdminSublimeVideo.chartsHelper.updateTotals()

      $(@el).resizable
        minWidth: 500
        minHeight: 350
        helper: "ui-resizable-helper"
        stop: (event, ui) =>
          this.render()

      setTimeout((=> $(window).scrollTop(currentScroll)), 1)

    this
