class MSVVideoTagBuilder.Views.IframeEmbed extends Backbone.View
  template: JST['video_tag_builder/templates/_iframe_embed']

  events:
    'change #iframe_src': 'updateSrc'

  initialize: ->
    _.bindAll this, 'render'

  #
  # EVENTS
  #
  updateSrc: (event) ->
    @model.set(src: event.target.value)

  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(iframe: @model))
    $(@el).show()

    this

  hide: ->
    $(@el).hide()
