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

    this

  renderErrors: ->
    srcInvalidErrorDiv = $('#poster_src_invalid')
    notFoundErrorDiv   = $('#poster_not_found')

    if @model.srcIsEmptyOrUrl() then srcInvalidErrorDiv.hide() else srcInvalidErrorDiv.show()
    if @model.get('found') then notFoundErrorDiv.hide() else notFoundErrorDiv.show()
