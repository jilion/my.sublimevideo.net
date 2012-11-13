class MSVVideoCodeGenerator.Views.Lightbox extends Backbone.View
  template: JST['video_code_generator/templates/_lightbox']

  events:
    'click input[name=initial_link]': 'updateInitialLink'
    'change #thumb_src':              'updateSrc'
    'change #thumb_width':            'updateThumbWidth'
    'click .reset':                   'resetThumbDimensions'

  initialize: ->
    @initialLink = 'image'
    @uiHelper    = new MSVVideoCodeGenerator.Helpers.UIAssetHelper 'thumb'

    _.bindAll this, 'render', 'renderExtraSettings', 'renderThumbWidth', 'renderThumbHeight', 'renderStatus'
    MSVVideoCodeGenerator.thumbnail.bind 'change:initialLink', this.renderExtraSettings
    MSVVideoCodeGenerator.thumbnail.bind 'change:src',         this.renderStatus
    MSVVideoCodeGenerator.thumbnail.bind 'change:found',       this.renderStatus
    MSVVideoCodeGenerator.thumbnail.bind 'change:thumbWidth',  this.renderThumbWidth
    MSVVideoCodeGenerator.thumbnail.bind 'change:thumbHeight', this.renderThumbHeight

  #
  # EVENTS
  #
  updateSrc: (event) ->
    MSVVideoCodeGenerator.thumbnail.setAndPreloadSrc(event.target.value)
    MSVVideoCodeGenerator.video.set(testAssetsUsed: false)

  updateThumbWidth: (event) ->
    MSVVideoCodeGenerator.thumbnail.setThumbWidth(parseInt(event.target.value))

  updateInitialLink: (event) ->
    MSVVideoCodeGenerator.thumbnail.set(initialLink: event.target.value)

  resetThumbDimensions: (event) ->
    MSVVideoCodeGenerator.thumbnail.setThumbWidth(MSVVideoCodeGenerator.thumbnail.get('width'))

    false

  #
  # BINDINGS
  #
  render: ->
    $(@el).html this.template(thumbnail: MSVVideoCodeGenerator.thumbnail)
    $(@el).show()
    this.renderStatus()

    this

  hide: ->
    $(@el).hide()

  renderExtraSettings: ->
    extraDiv = $('.extra')
    if MSVVideoCodeGenerator.thumbnail.get('initialLink') is 'image'
      extraDiv.show()
    else
      extraDiv.hide()
    this.renderStatus()

  renderThumbWidth: ->
    $("#thumb_width").attr(value: MSVVideoCodeGenerator.thumbnail.get('thumbWidth'))

  renderThumbHeight: ->
    $("#thumb_height").attr(value: MSVVideoCodeGenerator.thumbnail.get('thumbHeight'))

  renderStatus: ->
    @uiHelper.hideErrors()

    return if MSVVideoCodeGenerator.thumbnail.get('initialLink') isnt 'image' or MSVVideoCodeGenerator.thumbnail.srcIsEmpty()

    if !MSVVideoCodeGenerator.thumbnail.srcIsUrl()
      @uiHelper.renderError('src_invalid')
    else if !MSVVideoCodeGenerator.thumbnail.get('found')
      @uiHelper.renderError('not_found')
    else
      @uiHelper.renderValid()
