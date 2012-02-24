class MSVVideoCodeGenerator.Views.Sources extends Backbone.View
  template: JST['video_code_generator/templates/_sources']

  events:
    'change .source':    'updateSrc'
    'click .use_source': 'updateIsUsed'

  initialize: ->
    @settingsView = @options.settingsView

    _.bindAll this, 'render', 'refreshSettings', 'toggleSrcBox', 'renderEmbedWidth', 'renderEmbedHeight', 'renderSrcErrors', 'renderMimeTypeErrors', 'renderNotFoundErrors'
    @collection.bind 'change:src',             this.refreshSettings
    @collection.bind 'change:src',             this.renderSrcErrors
    @collection.bind 'change:currentMimeType', this.renderMimeTypeErrors
    @collection.bind 'change:found',           this.renderNotFoundErrors
    @collection.bind 'change:dataUID',         this.refreshSettings
    @collection.bind 'change:dataName',        this.refreshSettings
    @collection.bind 'change:isUsed',          this.toggleSrcBox
    @collection.bind 'change:width',           this.renderEmbedWidth
    @collection.bind 'change:height',          this.renderEmbedHeight

    this.render()

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
    $(@el).html(this.template(sources: @collection))

    this

  refreshSettings: ->
    @settingsView.render()

  toggleSrcBox: ->
    _.each @collection.allNonBase(), (source) ->
      srcBox = this.$("##{source.formatQuality()}_src_box")
      if source.get('isUsed') then srcBox.show() else srcBox.hide()
    this.refreshSettings()

  renderEmbedWidth: ->
    $("#embed_width").attr(value: @collection.mp4Base().get('embedWidth'))

  renderEmbedHeight: ->
    $("#embed_height").attr(value: @collection.mp4Base().get('embedHeight'))

  renderSrcErrors: (source) ->
    errorSrcInvalidDiv = $("##{source.formatQuality()}_src_invalid")
    if source.srcIsEmptyOrUrl()
      errorSrcInvalidDiv.hide()
    else
      errorSrcInvalidDiv.show()
    this.renderValidSource(source)

  renderMimeTypeErrors: (source) ->
    errorMimeTypeInvalidDiv = $("##{source.formatQuality()}_mime_type_invalid")

    if source.validMimeType()
      errorMimeTypeInvalidDiv.hide()
    else
      # errorMimeTypeInvalidDiv.html("\"#{source.get('currentMimeType')}\" is not a valid MIME-Type for this video, it should be \"#{source.expectedContentType()}\". <a href='http://docs.#{SublimeVideo.topDomainHost()}/troubleshooting'>Learn more</a>.")
      errorMimeTypeInvalidDiv.show()
    this.renderValidSource(source)

  renderNotFoundErrors: (source) ->
    errorNotFoundDiv = $("##{source.formatQuality()}_not_found")

    if source.get('found')
      errorNotFoundDiv.hide()
    else
      errorNotFoundDiv.show()
    this.renderValidSource(source)

  renderValidSource: (source) ->
    sourceEntryDiv = $("##{source.formatQuality()}_src_box")

    if source.srcIsUrl() and source.get('found') and source.validMimeType()
      sourceEntryDiv.addClass 'valid'
    else
      sourceEntryDiv.removeClass 'valid'

  #
  # PRIVATE
  #
  getSourceAndQuality: (id) ->
    _.first(id.split('_'), 2)
