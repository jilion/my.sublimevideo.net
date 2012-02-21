class MSVVideoCodeGenerator.Views.Sources extends Backbone.View
  template: JST['video_code_generator/templates/_sources']

  events:
    'change .source':    'updateSrc'
    'click .use_source': 'updateIsUsed'

  initialize: ->
    _.bindAll this, 'render', 'refreshSettings', 'toggleSrcBox', 'renderEmbedWidth', 'renderEmbedHeight'
    MSVVideoCodeGenerator.sources.bind 'change:src',      this.refreshSettings
    MSVVideoCodeGenerator.sources.bind 'change:dataUID',  this.refreshSettings
    MSVVideoCodeGenerator.sources.bind 'change:dataName', this.refreshSettings
    MSVVideoCodeGenerator.sources.bind 'change:isUsed',   this.toggleSrcBox
    MSVVideoCodeGenerator.sources.bind 'change:width',    this.renderEmbedWidth
    MSVVideoCodeGenerator.sources.bind 'change:height',   this.renderEmbedHeight

    this.render()

  #
  # EVENTS
  #
  updateSrc: (event) ->
    MSVVideoCodeGenerator.sources.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).setAndPreloadSrc(event.target.value)

  updateIsUsed: (event) ->
    MSVVideoCodeGenerator.sources.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).set(isUsed: event.target.checked)

  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(sources: MSVVideoCodeGenerator.sources))

    this

  refreshSettings: ->
    MSVVideoCodeGenerator.settingsView.render()

  toggleSrcBox: ->
    _.each MSVVideoCodeGenerator.sources.allNonBase(), (source) ->
      srcBox = this.$("##{source.formatQuality()}_src_box")
      if source.get('isUsed') then srcBox.show() else srcBox.hide()
    this.refreshSettings()

  renderEmbedWidth: ->
    $("#embed_width").attr(value: MSVVideoCodeGenerator.sources.mp4Base().get('embedWidth'))

  renderEmbedHeight: ->
    $("#embed_height").attr(value: MSVVideoCodeGenerator.sources.mp4Base().get('embedHeight'))

  #
  # PRIVATE
  #
  getSourceAndQuality: (id) ->
    _.first(id.split('_'), 2)
