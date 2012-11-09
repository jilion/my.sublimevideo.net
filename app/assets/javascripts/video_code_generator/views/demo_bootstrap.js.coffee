class MSVVideoCodeGenerator.Views.DemoBootstrap extends Backbone.View

  # events:
  #   'click #use_demo_assets': 'updateUseDemoAssets'
  #   'click a.reset':          'resetDemoAssets'

  # initialize: ->
  #   _.bindAll this, 'toggleResetDemoAssetsLink'

  # #
  # # EVENTS
  # #
  # updateUseDemoAssets: (event) ->
  #   resetFields = if !@model.get('testAssetsUsed') and this.anyAssetNotEmpty() then confirm('All fields will be overwritten, continue?') else !@model.get('testAssetsUsed')

  #   if resetFields
  #     this.resetAll()
  #     MSVVideoCodeGenerator.poster.setAndPreloadSrc(MSVVideoCodeGenerator.testAssets['poster'])
  #     MSVVideoCodeGenerator.thumbnail.reset()
  #     MSVVideoCodeGenerator.thumbnail.setAndPreloadSrc(MSVVideoCodeGenerator.testAssets['thumbnail'])
  #     _.each MSVVideoCodeGenerator.testAssets['sources'], (format, quality_and_src) ->
  #       _.each quality_and_src, (quality, src) ->
  #         source = MSVVideoCodeGenerator.sources.byFormatAndQuality([format, quality])
  #         source.setAndPreloadSrc(src)
  #         source.set(isUsed: true)
  #     MSVVideoCodeGenerator.video.get('sources').mp4Base().set(dataName: 'Midnight Sun')
  #     @model.set(testAssetsUsed: true)

  #     this.renderViews()

  # resetDemoAssets: (event) ->
  #   if this.anyAssetNotEmpty() and confirm('All fields will be cleared, continue?')
  #     this.resetAll()
  #     @model.set(testAssetsUsed: false)

  #     this.renderViews()

  #   false

  # toggleResetDemoAssetsLink: ->
  #   if @model.get('testAssetsUsed') then this.$("a.reset").show() else this.$(".reset").hide()

  # anyAssetNotEmpty: ->
  #   !MSVVideoCodeGenerator.poster.srcIsEmpty() or !MSVVideoCodeGenerator.thumbnail.srcIsEmpty() or (_.any MSVVideoCodeGenerator.sources, (src, key) -> src.get('isUsed') and !src.srcIsEmpty())

  # resetAll: ->
  #   MSVVideoCodeGenerator.poster.reset()
  #   MSVVideoCodeGenerator.thumbnail.reset()
  #   _.each MSVVideoCodeGenerator.demoSources, (src, key) ->
  #     source = MSVVideoCodeGenerator.sources.byFormatAndQuality(key.split('_'))
  #     source.reset()

  # renderViews: ->
  #   MSVVideoCodeGenerator.posterView.render()
  #   MSVVideoCodeGenerator.lightboxView.render() if @model.get('builderClass') is 'lightbox'
  #   MSVVideoCodeGenerator.sourcesView.render()
