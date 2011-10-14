class MSVVideoTagBuilder.Views.IframeEmbed extends Backbone.View
  template: JST['video_tag_builder/templates/_iframe_embed']

  events:
    'keyup #thumbnail':  'updateSrc'
    'change #thumbnail': 'updateSrc'

  initialize: ->
    _.bindAll this, 'render', 'preloadSrcAndUpdateExtraVisibility'
    @model.bind 'change:src',    this.preloadSrcAndUpdateExtraVisibility
    @model.bind 'change:width',  this.renderWidth
    @model.bind 'change:height', this.renderHeight

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

  preloadSrcAndUpdateExtraVisibility: ->
    if @model.srcIsUrl()
      @model.preloadSrc()
      $('.extra').show()
    else
      $('.extra').hide()
