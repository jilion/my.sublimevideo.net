class MSVVideoCodeGenerator.Views.Sources extends Backbone.View
  template: JST['video_code_generator/templates/_sources']

  events:
    'click input[name=video_origin]': 'updateVideoOrigin'
    'change .source':                 'updateSrc'
    'change #youtube_id':             'updateYouTubeID'
    'click .use_source':              'updateIsUsed'
    'click #start_with_hd':           'updateStartWithHd'

  initialize: ->
    this.initUIHelpers()

    _.bindAll this, 'render', 'renderStatus'
    MSVVideoCodeGenerator.video.bind 'change:origin', this.render
    # MSVVideoCodeGenerator.sources.bind 'change',             this.render
    MSVVideoCodeGenerator.sources.bind 'change:src',             this.render
    MSVVideoCodeGenerator.sources.bind 'change:currentMimeType', this.render
    MSVVideoCodeGenerator.sources.bind 'change:found',           this.render

    this.render()

  initUIHelpers: ->
    @uiHelpers = {}
    MSVVideoCodeGenerator.sources.each (source) =>
      @uiHelpers[source.cid] = new MSVVideoCodeGenerator.Helpers.UISourceHelper(source.formatQuality())

  #
  # EVENTS
  #
  updateVideoOrigin: (event) ->
    oldOrigin = MSVVideoCodeGenerator.video.get('origin')
    newOrigin = event.target.value

    switch newOrigin
      when 'test'
        this.setTestAssets(oldOrigin) unless MSVVideoCodeGenerator.video.get('testAssetsUsed')
      when 'own'
        this.resetTestAssets(oldOrigin) if MSVVideoCodeGenerator.video.get('testAssetsUsed')
      when 'youtube'
        this.setYouTube(oldOrigin)

    MSVVideoCodeGenerator.video.set(origin: if newOrigin is 'youtube' then 'youtube' else 'files')

  updateSrc: (event) ->
    MSVVideoCodeGenerator.sources.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).setAndPreloadSrc(event.target.value)

  updateYouTubeID: (event) ->
    MSVVideoCodeGenerator.video.set(youtubeId: event.target.value)
    MSVVideoCodeGenerator.video.set(dataUID: event.target.value)
    MSVVideoCodeGenerator.video.set(dataName: '')

  updateIsUsed: (event) ->
    MSVVideoCodeGenerator.sources.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).set(isUsed: event.target.checked)

  updateStartWithHd: (event) ->
    MSVVideoCodeGenerator.video.set(startWithHd: event.target.checked)

  #
  # BINDINGS
  #
  render: ->
    $(@el).find('#video_sources_fields').html this.template
      video: MSVVideoCodeGenerator.video
      sources: MSVVideoCodeGenerator.sources

    _.each MSVVideoCodeGenerator.sources.models, (source) => this.renderStatus(source)

    this

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

    $('.no_usable_source').show() unless MSVVideoCodeGenerator.video.viewable()

    _.each MSVVideoCodeGenerator.sources.allUsedNotEmpty(), (source) ->
      if !source.validMimeType()
        $('.mime_type_invalid').show()
        return

  #
  # PRIVATE
  #
  getSourceAndQuality: (id) ->
    _.first(id.split('_'), 2)

  setTestAssets: (oldOrigin) ->
    if oldOrigin is 'youtube' or !this.anyAssetNotEmpty() or confirm('All fields will be overwritten, continue?')
      MSVVideoCodeGenerator.builderRouter.setTestAssets()
      this.initUIHelpers()
      this.renderViews()

  resetTestAssets: (oldOrigin) ->
    if oldOrigin is 'youtube' or !this.anyTestAssetModified() or confirm('All fields will be cleared, continue?')
      MSVVideoCodeGenerator.builderRouter.resetTestAssets()
      this.initUIHelpers()
      this.renderViews()

  setYouTube: (oldOrigin) ->
    if !this.anyTestAssetModified() or !this.anyAssetNotEmpty() or confirm('All fields will be cleared, continue?')
      this.renderViews()

  anyTestAssetModified: ->
    _.any MSVVideoCodeGenerator.testAssets['sources'], (attributes) ->
      source = MSVVideoCodeGenerator.sources.byFormatAndQuality([attributes['format'], attributes['quality']])
      source.get('src') isnt attributes['src']

  anyAssetNotEmpty: ->
    anySourcesNotEmpty = _.any(MSVVideoCodeGenerator.sources.models, (src) ->
      src.get('isUsed') and !src.srcIsEmpty()
    )

    !MSVVideoCodeGenerator.poster.srcIsEmpty() or !MSVVideoCodeGenerator.thumbnail.srcIsEmpty() or anySourcesNotEmpty

  renderViews: ->
    MSVVideoCodeGenerator.settingsView.render()
    MSVVideoCodeGenerator.lightboxView.render() if MSVVideoCodeGenerator.video.get('displayInLightbox')
    this.render()
