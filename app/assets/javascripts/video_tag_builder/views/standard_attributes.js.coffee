class MSVVideoTagBuilder.Views.StandardAttributes extends Backbone.View

  initialize: ->

    this.render()

  #
  # BINDINGS
  #
  render: ->
    MSVVideoTagBuilder.posterView.render()
    MSVVideoTagBuilder.sourcesView.render()

    this
