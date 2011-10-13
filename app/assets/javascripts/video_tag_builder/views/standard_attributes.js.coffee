class MSVVideoTagBuilder.Views.StandardAttributes extends Backbone.View

  initialize: ->
    MSVVideoTagBuilder.posterView = new MSVVideoTagBuilder.Views.Poster
      model: MSVVideoTagBuilder.poster
      el: '#poster_box'

    MSVVideoTagBuilder.sourcesView = new MSVVideoTagBuilder.Views.Sources
      collection: MSVVideoTagBuilder.sources
      el: '#sources_box'

    this.render()

  render: ->
    MSVVideoTagBuilder.posterView.render()
    MSVVideoTagBuilder.sourcesView.render()

    this