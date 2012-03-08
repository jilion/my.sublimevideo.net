class MSVVideoCodeGenerator.Views.Poster extends Backbone.View
  template: JST['video_code_generator/templates/_poster']

  events:
    'change #poster_src': 'updateSrc'

  initialize: ->
    _.bindAll this, 'render', 'renderErrors'
    @model.bind 'change:src',   this.renderErrors
    @model.bind 'change:found', this.renderErrors

    this.render()

  #
  # EVENTS
  #
  updateSrc: (event) ->
    @model.setAndPreloadSrc(event.target.value)

  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(poster: @model))
    this.renderErrors()

    this

  renderErrors: ->
    this.hideErrors()

    return if @model.srcIsEmpty()

    if !@model.srcIsUrl()
      this.renderError('src_invalid')
    else if !@model.get('found')
      this.renderError('not_found')
    else
      this.renderValid()

  hideErrors: ->
    $("#poster_box").removeClass 'valid'
    $("#poster_src").removeClass 'errors'
    $("#poster_box .inline_alert").each -> $(this).hide()

  renderValid: ->
    $("#poster_box").addClass 'valid'

  renderError: (name) ->
    $("#poster_#{name}").show()
    $("#poster_src").addClass 'errors'
