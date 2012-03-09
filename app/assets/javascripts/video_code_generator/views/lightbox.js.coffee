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
    @uiHelper    = new MSVVideoCodeGenerator.Helpers.UIAssetHelper 'thumb'

    _.bindAll this, 'render', 'renderExtraSettings', 'renderThumbWidth', 'renderThumbHeight', 'renderStatus'
    @thumbnail.bind 'change:initialLink', this.renderExtraSettings
    @thumbnail.bind 'change:src',         this.renderStatus
    @thumbnail.bind 'change:found',       this.renderStatus
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
    $(@el).html this.template(thumbnail: @thumbnail)
    $(@el).show()
    this.renderStatus()

    this

  hide: ->
    $(@el).hide()

  renderExtraSettings: ->
    extraDiv = $('.extra')
    if @thumbnail.get('initialLink') is 'image'
      extraDiv.show()
    else
      extraDiv.hide()
    this.renderStatus()

  renderThumbWidth: ->
    $("#thumb_width").attr(value: @thumbnail.get('thumbWidth'))

  renderThumbHeight: ->
    $("#thumb_height").attr(value: @thumbnail.get('thumbHeight'))

  renderStatus: ->
    @uiHelper.hideErrors()

    return if @thumbnail.get('initialLink') isnt 'image' or @thumbnail.srcIsEmpty()

    if !@thumbnail.srcIsUrl()
      @uiHelper.renderError('src_invalid')
    else if !@thumbnail.get('found')
      @uiHelper.renderError('not_found')
    else
      @uiHelper.renderValid()
