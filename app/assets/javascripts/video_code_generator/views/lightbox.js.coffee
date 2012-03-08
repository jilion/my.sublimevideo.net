class MSVVideoCodeGenerator.Views.Lightbox extends Backbone.View
  template: JST['video_code_generator/templates/_lightbox']

  events:
    'click input[name=initial_link]': 'updateInitialLink'
    'change #thumb_src':              'updateSrc'
    'change #thumb_width':            'updateThumbWidth'
    'click #thumb_magnifying_glass':  'updateMagnifyingGlass'
    'click .reset':                   'resetThumbDimensions'

  initialize: ->
    @thumbnail   = @options.thumbnail
    @initialLink = 'image'

    _.bindAll this, 'render', 'renderExtraSettings', 'renderThumbWidth', 'renderThumbHeight', 'renderErrors'
    @thumbnail.bind 'change:initialLink', this.renderExtraSettings
    @thumbnail.bind 'change:src',         this.renderErrors
    @thumbnail.bind 'change:found',       this.renderErrors
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

  updateMagnifyingGlass: (event) ->
    @thumbnail.set(magnifyingGlass: event.target.checked)

  resetThumbDimensions: (event) ->
    @thumbnail.setThumbWidth(@thumbnail.get('width'))

    false

  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(thumbnail: @thumbnail))
    $(@el).show()
    this.renderErrors()

    this

  hide: ->
    $(@el).hide()

  renderExtraSettings: ->
    extraDiv = $('.extra')
    if @thumbnail.get('initialLink') is 'image'
      extraDiv.show()
    else
      extraDiv.hide()
    this.renderErrors()

  renderThumbWidth: ->
    $("#thumb_width").attr(value: @thumbnail.get('thumbWidth'))

  renderThumbHeight: ->
    $("#thumb_height").attr(value: @thumbnail.get('thumbHeight'))

  renderErrors: ->
    this.hideErrors()

    return if @thumbnail.get('initialLink') isnt 'image' or @thumbnail.srcIsEmpty()

    if !@thumbnail.srcIsUrl()
      this.renderError('src_invalid')
    else if !@thumbnail.get('found')
      this.renderError('not_found')
    else
      this.renderValid()

  hideErrors: ->
    $("#thumb_box").removeClass 'valid'
    $("#thumb_src").removeClass 'errors'
    $("#thumb_box .inline_alert").each -> $(this).hide()

  renderValid: ->
    $("#thumb_box").addClass 'valid'

  renderError: (name) ->
    $("#thumb_#{name}").show()
    $("#thumb_src").addClass 'errors'
