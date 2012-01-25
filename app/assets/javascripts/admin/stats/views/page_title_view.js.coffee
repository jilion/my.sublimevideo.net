class AdminSublimeVideo.Views.PageTitleView extends Backbone.View
  initialize: ->
    this.render()

  render: =>
    $(@el).html "SublimeVideo Statistics"
    this
