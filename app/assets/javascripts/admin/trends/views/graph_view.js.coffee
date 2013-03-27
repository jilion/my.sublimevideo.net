class AdminSublimeVideo.Views.GraphView extends Backbone.View
  initialize: ->
    this._listenToModelsEvents()

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    this.listenTo(@options.period, 'change', this.render)
    _.each @collection, (trend) =>
      this.listenTo(trend, 'change', this.render)

  render: =>
    if _.isEmpty(@collection) or _.all(@collection, (trends) -> trends.selected.length is 0)
      @$el.html('')
    else
      @$el.resizable('destroy')
      currentScroll = $(window).scrollTop()

      AdminSublimeVideo.chartsHelper.chart(@collection)
      AdminSublimeVideo.chartsHelper.updateTotals()

      @$el.resizable
        minWidth: 500
        minHeight: 350
        helper: "ui-resizable-helper"
        stop: (event, ui) =>
          this.render()

      setTimeout((=> $(window).scrollTop(currentScroll)), 1)

    this
