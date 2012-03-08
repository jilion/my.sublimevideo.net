class MSVVideoCodeGenerator.Views.DemoBootstrap extends Backbone.View

  events:
    'click #use_demo_assets': 'updateUseDemoAssets'

  #
  # EVENTS
  #
  updateUseDemoAssets: (event) ->
    MSVVideoCodeGenerator.poster.setAndPreloadSrc(MSVVideoCodeGenerator.demoPoster)
    _.each MSVVideoCodeGenerator.demoSources, (src, key) ->
      source = MSVVideoCodeGenerator.sources.byFormatAndQuality(key.split('_'))
      source.setAndPreloadSrc(src)
      source.set(isUsed: true)

    MSVVideoCodeGenerator.posterView.render()
    MSVVideoCodeGenerator.sourcesView.render()
