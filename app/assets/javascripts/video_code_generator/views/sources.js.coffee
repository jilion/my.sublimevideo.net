class MSVVideoCodeGenerator.Views.Sources extends Backbone.View
  template: JST['video_code_generator/templates/_sources']

  events:
    'change .source':    'updateSrc'
    'click .use_source': 'updateIsUsed'

  initialize: ->
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
    @uiHelper = {}
    @collection.each (source) =>
      @uiHelper[source.cid] = new MSVVideoCodeGenerator.Helpers.UISourceHelper(source.formatQuality())

  #
  # EVENTS
  #
  updateSrc: (event) ->
    @collection.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).setAndPreloadSrc(event.target.value)

  updateIsUsed: (event) ->
    @collection.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).set(isUsed: event.target.checked)

  #
  # BINDINGS
  #
  render: ->
    $(@el).html this.template(sources: @collection)
    _.each @collection.models, (source) => this.renderStatus(source)

    this

  refreshSettings: ->
    @settingsView.render()

  toggleSrcBox: ->
    _.each @collection.allNonBase(), (source) ->
      srcBox = this.$("##{source.formatQuality()}_box")
      if source.get('isUsed') then srcBox.show() else srcBox.hide()
    this.refreshSettings()

  renderEmbedWidth: ->
    $("#embed_width").attr(value: @collection.mp4Base().get('embedWidth'))

  renderEmbedHeight: ->
    $("#embed_height").attr(value: @collection.mp4Base().get('embedHeight'))

  renderStatus: (source) ->
    @uiHelper[source.cid].hideErrors()

    return if source.srcIsEmpty()

    unless @video.videoViewable()
      $('.no_usable_source').show()

    if !source.srcIsUrl()
      @uiHelper[source.cid].renderError('src_invalid')
    else if !source.get('found')
      @uiHelper[source.cid].renderError('not_found')
    else if !source.validMimeType()
      @uiHelper[source.cid].renderError('mime_type_invalid')
    else
      @uiHelper[source.cid].renderValid(source)

    this.renderAdditionalInformation()

  renderAdditionalInformation: ->
    $('.mime_type_invalid').hide()
    @collection.each (source) ->
      unless source.validMimeType()
        $('.mime_type_invalid').show()
        return

  #
  # PRIVATE
  #
  getSourceAndQuality: (id) ->
    _.first(id.split('_'), 2)
