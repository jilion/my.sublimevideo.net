class MSVVideoTagBuilder.Views.Settings extends Backbone.View
  template: JST['video_tag_builder/templates/_settings']

  events:
    'change #embed_width':  'updateEmbedWidth'
    'change #embed_height': 'updateEmbedHeight'
    'click #keep_ratio':    'updateKeepRatio'
    'click a.reset':        'resetEmbedDimensions'
    'click #start_with_hd': 'updateStartWithHd'

  initialize: ->
    _.bindAll this, 'render', 'renderEmbedWidth', 'renderEmbedHeight'
    @model.bind 'change:embedWidth',  this.renderEmbedWidth
    @model.bind 'change:embedHeight', this.renderEmbedHeight

    this.render()

  #
  # EVENTS
  #
  updateEmbedWidth: (event) ->
    embedWidth = parseInt(event.target.value)
    @model.setEmbedWidth(embedWidth)

  updateEmbedHeight: (event) ->
    embedHeight = parseInt(event.target.value)
    @model.set(embedHeight: embedHeight)

  updateKeepRatio: (event) ->
    @model.setKeepRatio(event.target.checked)
    this.render()

  resetEmbedDimensions: (event) ->
    @model.setKeepRatio(true)
    @model.setEmbedWidth(_.min([@model.get('width'), 852]))
    this.render()

    event.stopPropagation()
    false

  updateStartWithHd: (event) ->
    MSVVideoTagBuilder.builder.set(startWithHd: event.target.checked)

  #
  # BINDINGS
  #
  render: ->
    $(@el).html this.template
      source: @model
      sources: @collection

    this

  renderEmbedWidth: ->
    this.$("#embed_width").attr(value: @model.get('embedWidth'))

  renderEmbedHeight: ->
    this.$("#embed_height").attr(value: @model.get('embedHeight'))
