class MSVVideoCodeGenerator.Views.Settings extends Backbone.View
  template: JST['video_code_generator/templates/_settings']

  events:
    'change #embed_width':  'updateEmbedWidth'
    'change #embed_height': 'updateEmbedHeight'
    'click #keep_ratio':    'updateKeepRatio'
    'click a.reset':        'resetEmbedDimensions'
    'click #start_with_hd': 'updateStartWithHd'
    'change #data_name':    'updateDataName'
    'change #data_uid':     'updateDataUID'

  initialize: ->
    @builder = @options.builder

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

    false

  updateStartWithHd: (event) ->
    MSVVideoCodeGenerator.builder.set(startWithHd: event.target.checked)

  updateDataName: (event) ->
    @model.set(dataName: event.target.value)

  updateDataUID: (event) ->
    @model.set(dataUID: event.target.value)

  #
  # BINDINGS
  #
  render: ->
    $(@el).html this.template
      builder: @builder
      source: @model
      sources: @collection

    this

  renderEmbedWidth: ->
    this.$("#embed_width").attr(value: @model.get('embedWidth'))

  renderEmbedHeight: ->
    this.$("#embed_height").attr(value: @model.get('embedHeight'))
