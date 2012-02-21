class MSVVideoCodeGenerator.Views.Sources extends Backbone.View
  template: JST['video_code_generator/templates/_sources']

  events:
    'change .source':    'updateSrc'
    'click .use_source': 'updateIsUsed'

  initialize: ->
    _.bindAll this, 'render', 'refreshSettings', 'toggleSrcBox', 'renderEmbedWidth', 'renderEmbedHeight'
    @collection.bind 'change:src',      this.refreshSettings
    @collection.bind 'change:dataUID',  this.refreshSettings
    @collection.bind 'change:dataName', this.refreshSettings
    @collection.bind 'change:isUsed',   this.toggleSrcBox
    @collection.bind 'change:width',    this.renderEmbedWidth
    @collection.bind 'change:height',   this.renderEmbedHeight

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
    MSVVideoCodeGenerator.settingsView.render()

  toggleSrcBox: ->
    _.each @collection.allNonBase(), (source) ->
      srcBox = this.$("##{source.formatQuality()}_src_box")
      if source.get('isUsed') then srcBox.show() else srcBox.hide()
    this.refreshSettings()

  renderEmbedWidth: ->
    $("#embed_width").attr(value: @collection.mp4Base().get('embedWidth'))

  renderEmbedHeight: ->
    $("#embed_height").attr(value: @collection.mp4Base().get('embedHeight'))

  #
  # PRIVATE
  #
  getSourceAndQuality: (id) ->
    _.first(id.split('_'), 2)
