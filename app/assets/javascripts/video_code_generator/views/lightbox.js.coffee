class MSVVideoCodeGenerator.Views.Lightbox extends Backbone.View
  template: JST['video_code_generator/templates/_lightbox']

  events:
    'change #thumb_src':              'updateSrc'
    'change #thumb_width':            'updateThumbWidth'
    'click input[name=initial_link]': 'updateInitialLink'
    'click #thumb_magnifying_glass':  'updateMagnifyingGlass'
    'click .reset':                   'resetThumbDimensions'

  initialize: ->
    @thumbnail   = @options.thumbnail
    @initialLink = 'image'

    _.bindAll this, 'render', 'renderExtraAndErrors', 'renderNotFoundErrors', 'renderThumbWidth', 'renderThumbHeight'
    @thumbnail.bind 'change:src',         this.renderExtraAndErrors
    @thumbnail.bind 'change:found',       this.renderNotFoundErrors
    @thumbnail.bind 'change:thumbWidth',  this.renderThumbWidth
    @thumbnail.bind 'change:thumbHeight', this.renderThumbHeight

  #
  # EVENTS
  #
  updateSrc: (event) ->
    @thumbnail.setAndPreloadSrc(event.target.value)

  updateThumbWidth: (event) ->
    @thumbnail.setThumbWidth(parseInt(event.target.value))

  updateInitialLink: (event) ->
    @thumbnail.set(initialLink: event.target.value)

    this.render()

  updateMagnifyingGlass: (event) ->
    @thumbnail.set(magnifyingGlass: event.target.checked)

  resetThumbDimensions: (event) ->
    @thumbnail.setThumbWidth(@thumbnail.get('width'))

    event.stopPropagation()
    false

  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(thumbnail: @thumbnail))
    this.renderExtraAndErrors()
    $(@el).show()

    this

  hide: ->
    $(@el).hide()

  renderExtraAndErrors: ->
    extraDiv = $('.extra')
    errorDiv = $('#thumb_src_invalid')
    if @thumbnail.get('initialLink') is 'image'
      extraDiv.show()
      if @thumbnail.srcIsEmptyOrUrl() then errorDiv.hide() else errorDiv.show()
    else
      extraDiv.hide()
      errorDiv.hide()

  renderNotFoundErrors: ->
    errorDiv = $('#thumb_not_found')
    if @thumbnail.get('found')
      errorDiv.hide()
    else
      errorDiv.show()

  renderThumbWidth: ->
    $("#thumb_width").attr(value: @thumbnail.get('thumbWidth'))

  renderThumbHeight: ->
    $("#thumb_height").attr(value: @thumbnail.get('thumbHeight'))
