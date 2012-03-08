class MSVVideoCodeGenerator.Views.Sources extends Backbone.View
  template: JST['video_code_generator/templates/_sources']

  events:
    'change .source':    'updateSrc'
    'click .use_source': 'updateIsUsed'

  initialize: ->
    @settingsView = @options.settingsView

    _.bindAll this, 'render', 'refreshSettings', 'toggleSrcBox', 'renderEmbedWidth', 'renderEmbedHeight', 'renderSrcErrors'
    @collection.bind 'change:src',             this.refreshSettings
    @collection.bind 'change:src',             this.renderSrcErrors
    @collection.bind 'change:currentMimeType', this.renderSrcErrors
    @collection.bind 'change:found',           this.renderSrcErrors
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
    errorSrcInvalidDiv      = $("##{source.formatQuality()}_src_invalid")
    errorNotFoundDiv        = $("##{source.formatQuality()}_not_found")
    errorMimeTypeInvalidDiv = $("##{source.formatQuality()}_mime_type_invalid")
    sourceEntryDiv          = $("##{source.formatQuality()}_src_box")
    sourceEntryInput        = $("##{source.formatQuality()}_src")

    errorSrcInvalidDiv.hide()
    errorNotFoundDiv.hide()
    errorMimeTypeInvalidDiv.hide()
    sourceEntryDiv.removeClass 'valid'
    sourceEntryInput.addClass 'errors'

    if source.srcIsEmpty()
      sourceEntryDiv.removeClass 'valid'
      sourceEntryInput.removeClass 'errors'
    else if !source.srcIsUrl()
      errorSrcInvalidDiv.show()
    else if !source.get('found')
      errorNotFoundDiv.show()
    else if !source.validMimeType()
      errorMimeTypeInvalidDiv.show()
    else
      sourceEntryDiv.addClass 'valid'
      sourceEntryInput.removeClass 'errors'

  #
  # PRIVATE
  #
  getSourceAndQuality: (id) ->
    _.first(id.split('_'), 2)