class MSVVideoCodeGenerator.Views.Sources extends Backbone.View
  template: JST['video_code_generator/templates/sources']

  events:
    'click input[name=video_origin]': 'updateVideoOrigin'
    'change .source':                 'updateSrc'
    'change #youtube_id':             'updateYouTubeID'
    'click #start_with_hd':           'updateStartWithHd'

  initialize: ->
    this.initUIHelpers()

    _.bindAll this, 'render'
    MSVVideoCodeGenerator.video.bind   'change:origin',          this.render
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

    if oldOrigin is newOrigin
      false
    else
      changed = switch newOrigin
          when 'test'
            this.setTestAssets(oldOrigin)
          when 'own'
            this.clearTestAssets(oldOrigin)
          when 'youtube'
            this.setYouTube(oldOrigin)
      MSVVideoCodeGenerator.video.set(origin: newOrigin) if changed

      changed

  updateSrc: (event) ->
    $('#video_origin_own').attr('checked', true)
    MSVVideoCodeGenerator.sources.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).setAndPreloadSrc(event.target.value)

  updateYouTubeID: (event) ->
    MSVVideoCodeGenerator.video.set(youtubeId: event.target.value)
    MSVVideoCodeGenerator.video.set(dataUID: event.target.value)
    MSVVideoCodeGenerator.video.set(dataName: '')

  updateStartWithHd: (event) ->
    MSVVideoCodeGenerator.video.set(startWithHd: event.target.checked)

  #
  # BINDINGS
  #
  render: ->
    $(@el).find('#video_sources_fields').html this.template
      video: MSVVideoCodeGenerator.video

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
    if oldOrigin is 'youtube' or this.allAssetsEmpty() or confirm('All fields will be overwritten, continue?')
      MSVVideoCodeGenerator.builderRouter.setTestAssets()
      this.initUIHelpers()
      this.renderViews()
      true
    else
      false

  clearTestAssets: (oldOrigin) ->
    if oldOrigin is 'youtube' or this.noTestAssetModified() or confirm('All fields will be cleared, continue?')
      MSVVideoCodeGenerator.builderRouter.clearTestAssets() if this.noTestAssetModified()
      this.initUIHelpers()
      this.renderViews()
      true
    else
      false

  setYouTube: (oldOrigin) ->
    this.renderViews()
    true

  noTestAssetModified: ->
    _.all MSVVideoCodeGenerator.testAssets['sources'], (attributes) ->
      source = MSVVideoCodeGenerator.sources.byFormatAndQuality([attributes['format'], attributes['quality']])
      source.get('src') is attributes['src']

  allAssetsEmpty: ->
    allSourcesEmpty = _.all(MSVVideoCodeGenerator.sources.models, (src) ->
      src.srcIsEmpty()
    )

    MSVVideoCodeGenerator.poster.srcIsEmpty() and MSVVideoCodeGenerator.thumbnail.srcIsEmpty() and allSourcesEmpty

  renderViews: ->
    MSVVideoCodeGenerator.settingsView.render()
    MSVVideoCodeGenerator.lightboxView.render()
    this.render()
