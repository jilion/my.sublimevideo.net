class MSVVideoTagBuilder.Views.EmbedDimensions extends Backbone.View
  template: JST['video_tag_builder/templates/_embed_dimensions']

  events:
    'change #embed_width':  'updateEmbedWidth'
    'change #embed_height': 'updateEmbedHeight'
    'click #keep_ratio':    'updateKeepRatio'
    'click .reset':         'resetEmbedDimensions'

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
    @model.setEmbedWidth(_.min([@model.get('width'), 858]))
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
    this.scrollToEl()

  renderEmbedHeight: ->
    this.$("#embed_height").attr(value: @model.get('embedHeight'))
    this.scrollToEl()

  scrollToEl: ->
    $(window).scrollTop($(@el).position().top)
