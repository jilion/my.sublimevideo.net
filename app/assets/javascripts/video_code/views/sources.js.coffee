class MSVVideoCode.Views.Sources extends Backbone.View
  template: JST['video_code/templates/sources']

  events:
    'click input[name=video_origin]': 'updateVideoOrigin'
    'change .source':                 'updateSrc'
    'change #youtube_id':             'updateYouTubeID'
    'click #start_with_hd':           'updateStartWithHd'

  initialize: ->
    this.initUIHelpers()

    _.bindAll this, 'render'
    MSVVideoCode.video.bind   'change:origin',          this.render
    MSVVideoCode.sources.bind 'change:src',             this.render
    MSVVideoCode.sources.bind 'change:currentMimeType', this.render
    MSVVideoCode.sources.bind 'change:found',           this.render

    this.render()

  initUIHelpers: ->
    @uiHelpers = {}
    MSVVideoCode.sources.each (source) =>
      @uiHelpers[source.cid] = new MSVVideoCode.Helpers.UISourceHelper(source.formatQuality())

  #
  # EVENTS
  #
  updateVideoOrigin: (event) ->
    oldOrigin = MSVVideoCode.video.get('origin')
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
      MSVVideoCode.video.set(origin: newOrigin) if changed

      changed

  updateSrc: (event) ->
    $('#video_origin_own').attr('checked', true)
    MSVVideoCode.sources.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).setAndPreloadSrc(event.target.value)

  updateYouTubeID: (event) ->
    MSVVideoCode.video.set(youtubeId: event.target.value)
    MSVVideoCode.video.set(dataUID: event.target.value)
    MSVVideoCode.video.set(dataName: '')

  updateStartWithHd: (event) ->
    MSVVideoCode.video.set(startWithHd: event.target.checked)

  #
  # BINDINGS
  #
  render: ->
    $(@el).find('#video_sources_fields').html this.template
      video: MSVVideoCode.video

    _.each MSVVideoCode.sources.models, (source) => this.renderStatus(source)

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

    $('.no_usable_source').show() unless MSVVideoCode.video.viewable()

    _.each MSVVideoCode.sources.allUsedNotEmpty(), (source) ->
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
      MSVVideoCode.builderRouter.setTestAssets()
      this.initUIHelpers()
      this.renderViews()
      true
    else
      false

  clearTestAssets: (oldOrigin) ->
    if oldOrigin is 'youtube' or this.noTestAssetModified() or confirm('All fields will be cleared, continue?')
      MSVVideoCode.builderRouter.clearTestAssets() if this.noTestAssetModified()
      this.initUIHelpers()
      this.renderViews()
      true
    else
      false

  setYouTube: (oldOrigin) ->
    this.renderViews()
    true

  noTestAssetModified: ->
    _.all MSVVideoCode.testAssets['sources'], (attributes) ->
      source = MSVVideoCode.sources.byFormatAndQuality([attributes['format'], attributes['quality']])
      source.get('src') is attributes['src']

  allAssetsEmpty: ->
    allSourcesEmpty = _.all(MSVVideoCode.sources.models, (src) ->
      src.srcIsEmpty()
    )

    MSVVideoCode.poster.srcIsEmpty() and MSVVideoCode.thumbnail.srcIsEmpty() and allSourcesEmpty

  renderViews: ->
    MSVVideoCode.settingsView.render()
    MSVVideoCode.lightboxView.render()
    this.render()
