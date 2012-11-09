class MSVVideoCodeGenerator.Views.Sources extends Backbone.View
  template: JST['video_code_generator/templates/_sources']

  events:
    'click input[name=video_origin]': 'updateVideoOrigin'
    'change .source':                 'updateSrc'
    'click .use_source':              'updateIsUsed'
    'click #start_with_hd':           'updateStartWithHd'

  initialize: ->
    @builder      = @options.builder
    @video        = @options.video
    @settingsView = @options.settingsView
    this.initUIHelpers()

    _.bindAll this, 'render', 'refreshSettings', 'toggleSrcBox', 'renderEmbedWidth', 'renderEmbedHeight', 'renderStatus'
    @collection.bind 'change:src',             this.refreshSettings
    @collection.bind 'change:src',             this.renderStatus
    @collection.bind 'change:currentMimeType', this.renderStatus
    @collection.bind 'change:found',           this.renderStatus
    @collection.bind 'change:dataUID',         this.refreshSettings
    @collection.bind 'change:dataName',        this.refreshSettings
    @collection.bind 'change:isUsed',          this.toggleSrcBox
    @collection.bind 'change:width',           this.renderEmbedWidth
    @collection.bind 'change:height',          this.renderEmbedHeight

    this.render()

  initUIHelpers: ->
    @uiHelpers = {}
    @collection.each (source) =>
      @uiHelpers[source.cid] = new MSVVideoCodeGenerator.Helpers.UISourceHelper(source.formatQuality())

  #
  # EVENTS
  #
  updateVideoOrigin: (event) ->
    oldOrigin = @video.get('origin')
    newOrigin = event.target.value
    @video.set(origin: if newOrigin is 'youtube' then 'youtube' else 'files')

    switch newOrigin
      when 'test'
        this.setTestAssets(oldOrigin)
      when 'own'
        this.resetTestAssets(oldOrigin)
      else
        this.setYouTube(oldOrigin)

  updateSrc: (event) ->
    @collection.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).setAndPreloadSrc(event.target.value)

  updateIsUsed: (event) ->
    @collection.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).set(isUsed: event.target.checked)

  updateStartWithHd: (event) ->
    @builder.set(startWithHd: event.target.checked)

  #
  # BINDINGS
  #
  render: ->
    $(@el).find('#video_sources_settings').html this.template
      builder: @builder
      video: @video
      sources: @collection

    _.each @collection.models, (source) => this.renderStatus(source)

    this

  refreshSettings: ->
    @builder.set(testAssetsUsed: false)
    @settingsView.render()

  toggleSrcBox: ->
    _.each @collection.allNonBase(), (source) =>
      if source.get('isUsed') then @uiHelpers[source.cid].show() else @uiHelpers[source.cid].hide()
      this.renderStatus(source)
    this.refreshSettings()

  renderEmbedWidth: ->
    $("#embed_width").attr(value: @collection.mp4Base().get('embedWidth'))

  renderEmbedHeight: ->
    $("#embed_height").attr(value: @collection.mp4Base().get('embedHeight'))

  renderStatus: (source) ->
    @uiHelpers[source.cid].hideErrors()

    this.renderAdditionalInformation()

    return if source.srcIsEmpty()

    if !source.srcIsUrl()
      @uiHelpers[source.cid].renderError('src_invalid')
    else if !source.get('found')
      @uiHelpers[source.cid].renderError('not_found')
    else if !source.validMimeType()
      @uiHelpers[source.cid].renderError('mime_type_invalid')
    else
      @uiHelpers[source.cid].renderValid(source)

  renderAdditionalInformation: ->
    $('.no_usable_source').hide()
    $('.mime_type_invalid').hide()

    $('.no_usable_source').show() unless @video.viewable()

    _.each @collection.allUsedNotEmpty(), (source) ->
      if !source.validMimeType()
        $('.mime_type_invalid').show()
        return

  #
  # PRIVATE
  #
  getSourceAndQuality: (id) ->
    _.first(id.split('_'), 2)

  setTestAssets: (oldOrigin) ->
    resetFields = if !@builder.get('testAssetsUsed') and this.anyAssetNotEmpty()
      confirm('All fields will be overwritten, continue?')
    else
      !@builder.get('testAssetsUsed')

    if resetFields
      @builder.setTestAssets()
      @collection = MSVVideoCodeGenerator.sources
      this.renderViews()

  resetTestAssets: (oldOrigin) ->
    if oldOrigin or !this.anyTestAssetModified() or confirm('All fields will be cleared, continue?')
      @builder.resetTestAssets()
      this.renderViews()

  setYouTube: (oldOrigin) ->
    this.render()

  anyTestAssetModified: ->
    _.any MSVVideoCodeGenerator.testAssets['sources'], (attributes) ->
      source = MSVVideoCodeGenerator.sources.byFormatAndQuality([attributes['format'], attributes['quality']])
      source.get('src') isnt attributes['src']

  anyAssetNotEmpty: ->
    !MSVVideoCodeGenerator.poster.srcIsEmpty() or !MSVVideoCodeGenerator.thumbnail.srcIsEmpty() or (_.any MSVVideoCodeGenerator.sources, (src, key) -> src.get('isUsed') and !src.srcIsEmpty())

  renderViews: ->
    MSVVideoCodeGenerator.posterView.render()
    MSVVideoCodeGenerator.lightboxView.render() if @builder.get('builderClass') is 'lightbox'
    this.render()
