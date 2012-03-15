class MSVVideoCodeGenerator.Views.Poster extends Backbone.View
  template: JST['video_code_generator/templates/_poster']

  events:
    'change #poster_src': 'updateSrc'

  initialize: ->
    @builder  = @options.builder
    @uiHelper = new MSVVideoCodeGenerator.Helpers.UIAssetHelper 'poster'

    _.bindAll this, 'render', 'renderStatus'
    @model.bind 'change', this.renderStatus

    this.render()

  #
  # EVENTS
  #
  updateSrc: (event) ->
    @model.setAndPreloadSrc(event.target.value)
    @builder.set(demoAssetsUsed: false)

  #
  # BINDINGS
  #
  render: ->
    $(@el).html this.template(poster: @model)
    this.renderStatus()

    this

  renderStatus: ->
    @uiHelper.hideErrors()

    return if @model.srcIsEmpty()

    if !@model.srcIsUrl()
      @uiHelper.renderError('src_invalid')
    else if !@model.get('found')
      @uiHelper.renderError('not_found')
    else
      @uiHelper.renderValid()
