class MSVVideoCodeGenerator.Views.DemoBootstrap extends Backbone.View

  events:
    'click #use_demo_assets': 'updateUseDemoAssets'

  #
  # EVENTS
  #
  updateUseDemoAssets: (event) ->
    # console.log(MSVVideoCodeGenerator.video.get('poster'));
    MSVVideoCodeGenerator.poster.set(src: MSVVideoCodeGenerator.demoPoster)
    # console.log(MSVVideoCodeGenerator.video.get('poster'));
    _.each MSVVideoCodeGenerator.demoSources, (source, key) ->
      MSVVideoCodeGenerator.sources.byFormatAndQuality(key.split('_')).set(src: source, isUsed: true)
      # MSVVideoCodeGenerator.video.set(sources: MSVVideoCodeGenerator.demoSources)
    # MSVVideoCodeGenerator.poster  = MSVVideoCodeGenerator.demoPoster
    # MSVVideoCodeGenerator.sources = MSVVideoCodeGenerator.demoSources

    MSVVideoCodeGenerator.posterView.render()
    MSVVideoCodeGenerator.sourcesView.render()
    MSVVideoCodeGenerator.codeView.render()

    # @poster.set(src: MSVVideoCodeGenerator.demoPoster.get('src'))
    # @sources = MSVVideoCodeGenerator.demoSources
