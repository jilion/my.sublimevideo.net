class MSVVideoTagBuilder.Views.EmbedDimensions extends Backbone.View
  template: JST['video_tag_builder/templates/_embed_dimensions']

  events:
    'keyup #embed_width':  'updateEmbedWidth'
    'change #embed_width': 'updateEmbedWidth'
    'click #keep_ratio':   'updateKeepRatio'
    'click .reset':        'resetEmbedDimensions'

  initialize: ->
    _.bindAll this, 'render', 'renderEmbedWidth', 'renderEmbedHeight'
    @model.bind 'change:embedWidth',  this.renderEmbedWidth
    @model.bind 'change:embedHeight', this.renderEmbedHeight

    this.render()

  #
  # EVENTS
  #
  updateEmbedWidth: (event) ->
    event.target.value = parseInt(event.target.value)
    @model.setEmbedWidth(event.target.value)

  updateKeepRatio: (event) ->
    @model.setKeepRatio(event.target.checked)
    this.render()

  resetEmbedDimensions: (event) ->
    @model.setKeepRatio(true)
    this.render()

    event.stopPropagation()
    false

  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(source: @model))

    this

  renderEmbedWidth: ->
    this.$("#embed_width").attr(value: @model.get('embedWidth'))

  renderEmbedHeight: ->
    this.$("#embed_height").attr(value: @model.get('embedHeight'))
