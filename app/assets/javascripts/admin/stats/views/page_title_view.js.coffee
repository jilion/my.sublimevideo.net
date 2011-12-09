class SVStats.Views.PageTitleView extends Backbone.View

  initialize: ->
    this.render()

  render: =>
    $(@el).html "SublimeVideo Admin - Stats"
    this
