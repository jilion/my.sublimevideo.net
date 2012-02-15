class MSVVideoCodeGenerator.Views.Lightbox extends Backbone.View
  template: JST['video_code_generator/templates/_lightbox']

  events:
    'change #thumb_src':              'updateSrc'
    'change #thumb_width':            'updateThumbWidth'
    'click input[name=initial_link]': 'updateInitialLink'
    'click #thumb_magnifying_glass':  'updateMagnifyingGlass'
    'click .reset':                   'resetThumbDimensions'

  initialize: ->
    @thumbnail = @options.thumbnail
    @initialLink = 'image'

    _.bindAll this, 'render', 'renderExtra', 'renderThumbWidth', 'renderThumbHeight', 'renderInvalidSrcError'
    @thumbnail.bind 'change:src',         this.renderExtra
    @thumbnail.bind 'change:thumbWidth',  this.renderThumbWidth
    @thumbnail.bind 'change:thumbHeight', this.renderThumbHeight
    @thumbnail.bind 'change:validSrc',    this.renderInvalidSrcError

  #
  # EVENTS
  #
  updateSrc: (event) ->
    @thumbnail.setAndPreloadSrc(event.target.value)

  updateThumbWidth: (event) ->
    event.target.value = parseInt(event.target.value)
    @thumbnail.setThumbWidth(event.target.value)

  updateInitialLink: (event) ->
    _.each $('input[name=initial_link]'), (el) =>
      @initialLink = el.value if el.checked

    this.render()

  updateMagnifyingGlass: (event) ->
    @thumbnail.set(magnifyingGlass: event.target.checked)

  resetThumbDimensions: (event) ->
    @thumbnail.setThumbWidth(@thumbnail.get('width'))

    event.stopPropagation()
    false

  initialLinkIsImage: ->
    @initialLink is 'image'

  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(thumbnail: @thumbnail, initialLink: @initialLink))
    this.renderExtra()
    this.renderInvalidSrcError()
    $(@el).show()

    this

  hide: ->
    $(@el).hide()

  renderExtra: ->
    extraDiv = $('.extra')
    if this.initialLinkIsImage() then extraDiv.show() else extraDiv.hide()

  renderThumbWidth: ->
    $("#thumb_width").attr(value: @thumbnail.get('thumbWidth'))

  renderThumbHeight: ->
    $("#thumb_height").attr(value: @thumbnail.get('thumbHeight'))

  renderInvalidSrcError: ->
    errorDiv = $('#thumb_src_invalid')
    if !this.initialLinkIsImage() or @thumbnail.get('validSrc') then errorDiv.hide() else errorDiv.show()
