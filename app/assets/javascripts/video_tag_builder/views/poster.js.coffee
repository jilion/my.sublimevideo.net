class MSVVideoTagBuilder.Views.Poster extends Backbone.View
  template: JST['video_tag_builder/templates/_poster']

  events:
    'keyup #poster': 'updateSrc'
    'change #poster': 'updateSrc'

  initialize: ->
    _.bindAll this, 'render', 'preloadSrc'
    @model.bind 'change:src', this.preloadSrc

  updateSrc: (event) ->
    @model.set(src: event.target.value)

  preloadSrc: ->
    if @model.srcIsUrl()
      @model.preloadSrc()
      $('.extra').show()
    else
      $('.extra').hide()

  render: ->
    $(@el).html(this.template(model: @model))

    this