class MSVVideoCodeGenerator.Views.Poster extends Backbone.View
  template: JST['video_code_generator/templates/_poster']

  events:
    'change #poster_src': 'updateSrc'

  initialize: ->
    _.bindAll this, 'render', 'preloadSrc'
    @model.bind 'change:src', this.preloadSrc

    this.render()

  #
  # EVENTS
  #
  updateSrc: (event) ->
    @model.set(src: event.target.value)

  preloadSrc: ->
    if @model.srcIsUrl()
      @model.preloadSrc()

  #
  # BINDINGS
  #
  render: ->
    console.log(@model);
    $(@el).html(this.template(poster: @model))

    this
