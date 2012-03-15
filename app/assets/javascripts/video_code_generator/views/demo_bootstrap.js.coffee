class MSVVideoCodeGenerator.Views.DemoBootstrap extends Backbone.View

  events:
    'click #use_demo_assets': 'updateUseDemoAssets'
    'click a.reset':          'resetDemoAssets'

  initialize: ->
    _.bindAll this, 'toggleResetDemoAssetsLink'
    @model.bind 'change:demoAssetsUsed', this.toggleResetDemoAssetsLink

  #
  # EVENTS
  #
  updateUseDemoAssets: (event) ->
    MSVVideoCodeGenerator.poster.setAndPreloadSrc(MSVVideoCodeGenerator.demoPoster)
    _.each MSVVideoCodeGenerator.demoSources, (src, key) ->
      source = MSVVideoCodeGenerator.sources.byFormatAndQuality(key.split('_'))
      source.setAndPreloadSrc(src)
      source.set(isUsed: true)
    @model.set(demoAssetsUsed: true)

    MSVVideoCodeGenerator.posterView.render()
    MSVVideoCodeGenerator.sourcesView.render()

  resetDemoAssets: (event) ->
    MSVVideoCodeGenerator.poster.setAndPreloadSrc('')
    _.each MSVVideoCodeGenerator.demoSources, (src, key) ->
      source = MSVVideoCodeGenerator.sources.byFormatAndQuality(key.split('_'))
      source.setAndPreloadSrc('')
      # source.set(isUsed: true)
    @model.set(demoAssetsUsed: false)

    MSVVideoCodeGenerator.posterView.render()
    MSVVideoCodeGenerator.sourcesView.render()

    false

  toggleResetDemoAssetsLink: ->
    if @model.get('demoAssetsUsed') then this.$("a.reset").show() else this.$(".reset").hide()