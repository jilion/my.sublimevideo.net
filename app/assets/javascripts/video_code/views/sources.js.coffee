class MSVVideoCode.Views.Sources extends Backbone.View
  template: JST['video_code/templates/sources']

  events:
    'click input[name=video_origin]': 'updateVideoOrigin'
    'change .source':                 'updateSrc'
    'change #youtube_id':             'updateYouTubeID'
    'click #start_with_hd':           'updateStartWithHd'

  initialize: ->
    this._initUIHelpers()
    @placeholder = $(@el).find('#video_sources_fields')

    _.bindAll this, 'render'
    MSVVideoCode.video.bind   'change:origin',          this.render
    MSVVideoCode.sources.bind 'change:src',             this.render
    MSVVideoCode.sources.bind 'change:currentMimeType', this.render
    MSVVideoCode.sources.bind 'change:found',           this.render

    this.render()

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
            this._setTestAssets(oldOrigin)
          when 'own'
            this._clearAssets(oldOrigin)
          when 'youtube'
            this._setYouTube(oldOrigin)
      MSVVideoCode.video.set(origin: newOrigin) if changed

      changed

  updateSrc: (event) ->
    $('#video_origin_own').prop('checked', true)
    MSVVideoCode.sources.byFormatAndQuality(this._getSourceAndQuality(event.target.id)).setAndPreloadSrc(event.target.value)

  updateYouTubeID: (event) ->
    MSVVideoCode.video.setYouTubeId(event.target.value)
    MSVVideoCode.video.set(uid: MSVVideoCode.video.get('youTubeId'))
    MSVVideoCode.video.set(title: '')

    this.render()

  updateStartWithHd: (event) ->
    MSVVideoCode.video.set(startWithHd: event.target.checked)

  #
  # BINDINGS
  #
  render: ->
    @placeholder.html this.template()

    _.each MSVVideoCode.sources.models, (source) => this._renderStatus(source)

    this

  _renderStatus: (source) ->
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
      @uiHelpers[source.cid].renderValid()

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
  _initUIHelpers: ->
    @uiHelpers = {}
    MSVVideoCode.sources.each (source) =>
      @uiHelpers[source.cid] = new MSVVideoCode.Helpers.UIAssetHelper(source.formatQuality())

  _getSourceAndQuality: (id) ->
    _.first(id.split('_'), 2)

  _setTestAssets: (oldOrigin) ->
    if oldOrigin is 'youtube' or this._allAssetsEmpty() or confirm('All fields will be overwritten, continue?')
      MSVVideoCode.builderRouter.setTestAssets()
      this.initUIHelpers()
      this._renderViews()
      true
    else
      false

  _clearAssets: (oldOrigin) ->
    if oldOrigin is 'youtube' or this._allAssetsEmpty() or this._noTestAssetModified() or confirm('All fields will be cleared, continue?')
      MSVVideoCode.builderRouter.clearAssets()
      this.initUIHelpers()
      this._renderViews()
      true
    else
      false

  _setYouTube: (oldOrigin) ->
    if this._clearAssets(oldOrigin)
      this._renderViews()
      true
    else
      false

  _noTestAssetModified: ->
    _.all MSVVideoCode.testAssets['sources'], (attributes) ->
      source = MSVVideoCode.sources.byFormatAndQuality([attributes['format'], attributes['quality']])
      source.get('src') is attributes['src']

  _allAssetsEmpty: ->
    allSourcesEmpty = _.all(MSVVideoCode.sources.models, (src) ->
      src.srcIsEmpty()
    )

    MSVVideoCode.poster.srcIsEmpty() and MSVVideoCode.thumbnail.srcIsEmpty() and allSourcesEmpty

  _renderViews: ->
    MSVVideoCode.settingsView.render()
    MSVVideoCode.lightboxView.render()
    this.render()
