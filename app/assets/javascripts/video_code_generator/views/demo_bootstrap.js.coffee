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
    resetFields = if !@model.get('demoAssetsUsed') and this.anyAssetNotEmpty() then confirm('All fields will be overwritten, continue?') else true

    if resetFields
      this.resetAll()
      MSVVideoCodeGenerator.poster.setAndPreloadSrc(MSVVideoCodeGenerator.demoPoster)
      MSVVideoCodeGenerator.thumbnail.reset()
      MSVVideoCodeGenerator.thumbnail.setAndPreloadSrc(MSVVideoCodeGenerator.demoThumbnail)
      _.each MSVVideoCodeGenerator.demoSources, (src, key) ->
        source = MSVVideoCodeGenerator.sources.byFormatAndQuality(key.split('_'))
        source.setAndPreloadSrc(src)
        source.set(isUsed: true)
      @model.set(demoAssetsUsed: true)

      this.renderViews()

  resetDemoAssets: (event) ->
    this.resetAll()
    @model.set(demoAssetsUsed: false)

    this.renderViews()
    false

  toggleResetDemoAssetsLink: ->
    if @model.get('demoAssetsUsed') then this.$("a.reset").show() else this.$(".reset").hide()

  anyAssetNotEmpty: ->
    !MSVVideoCodeGenerator.poster.srcIsEmpty() or !MSVVideoCodeGenerator.thumbnail.srcIsEmpty() or (_.any MSVVideoCodeGenerator.sources, (src, key) -> src.get('isUsed') and !src.srcIsEmpty())

  resetAll: ->
    MSVVideoCodeGenerator.poster.reset()
    MSVVideoCodeGenerator.thumbnail.reset()
    _.each MSVVideoCodeGenerator.demoSources, (src, key) ->
      source = MSVVideoCodeGenerator.sources.byFormatAndQuality(key.split('_'))
      source.reset()

  renderViews: ->
    MSVVideoCodeGenerator.posterView.render()
    MSVVideoCodeGenerator.lightboxView.render() if @model.get('builderClass') is 'lightbox'
    MSVVideoCodeGenerator.sourcesView.render()
