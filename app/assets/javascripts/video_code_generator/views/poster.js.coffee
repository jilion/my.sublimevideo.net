class MSVVideoCodeGenerator.Views.Poster extends Backbone.View
  template: JST['video_code_generator/templates/_poster']

  events:
    'change #poster_src': 'updateSrc'

  initialize: ->
    _.bindAll this, 'render'

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
