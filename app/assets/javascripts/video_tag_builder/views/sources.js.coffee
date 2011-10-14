class MSVVideoTagBuilder.Views.Sources extends Backbone.View
  template: JST['video_tag_builder/templates/_sources']

  events:
    'keyup #mp4_normal_src':  'updateSrc'
    'change #mp4_normal_src': 'updateSrc'
    'click .use_source':      'updateIsUsed'
    'click .reset':           'resetEmbedDimensions'

  initialize: ->
    _.bindAll this, 'render', 'toggleSrcBox', 'renderEmbedWidth', 'renderEmbedHeight'
    @collection.bind 'change:isUsed', this.toggleSrcBox
    @collection.bind 'change:width',  this.renderEmbedWidth
    @collection.bind 'change:height', this.renderEmbedHeight

    this.render()

  #
  # EVENTS
  #
  updateSrc: (event) ->
    @collection.findByFormatAndQuality(this.getSourceAndQuality(event.target.id)).setSrc(event.target.value)

  updateIsUsed: (event) ->
    @collection.findByFormatAndQuality(this.getSourceAndQuality(event.target.id)).set(isUsed: event.target.checked)

  resetEmbedDimensions: (event) ->
    @collection.mp4Normal().setEmbedWidth(@collection.mp4Normal().get('width'))

    event.stopPropagation()
    false

  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(sources: @collection))

    this

  toggleSrcBox: ->
    _.each @collection.nonNormal(), (source) ->
      srcBox = this.$("##{source.formatQuality()}_src_box")
      if source.get('isUsed') then srcBox.show() else srcBox.hide()

  renderEmbedWidth: ->
    $("#embed_width").attr(value: @collection.mp4Normal().get('embedWidth'))

  renderEmbedHeight: ->
    $("#embed_height").attr(value: @collection.mp4Normal().get('embedHeight'))

  #
  # PRIVATE
  #
  getSourceAndQuality: (id) ->
    _.first(id.split('_'), 2)
