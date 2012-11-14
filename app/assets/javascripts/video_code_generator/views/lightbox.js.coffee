class MSVVideoCodeGenerator.Views.Lightbox extends Backbone.View
  template: JST['video_code_generator/templates/lightbox']

  events:
    'click #use_lightbox':            'updateDisplayInLightbox'
    'click input[name=initial_link]': 'updateInitialLink'
    'change #thumb_src':              'updateSrc'
    'change #thumb_width':            'updateThumbWidth'
    'change #thumb_height':           'updateThumbHeight'
    'click .reset':                   'resetThumbDimensions'

  initialize: ->
    @uiHelper = new MSVVideoCodeGenerator.Helpers.UIAssetHelper 'thumb'

    _.bindAll this, 'render', 'renderExtraSettings', 'renderThumbWidth', 'renderThumbHeight', 'renderStatus'
    MSVVideoCodeGenerator.thumbnail.bind 'change:initialLink', this.renderExtraSettings
    MSVVideoCodeGenerator.thumbnail.bind 'change:src',         this.renderStatus
    MSVVideoCodeGenerator.thumbnail.bind 'change:found',       this.renderStatus
    MSVVideoCodeGenerator.thumbnail.bind 'change:thumbWidth',  this.renderThumbWidth
    MSVVideoCodeGenerator.thumbnail.bind 'change:thumbHeight', this.renderThumbHeight

    this.render()

  #
  # EVENTS
  #
  updateDisplayInLightbox: (event) ->
    MSVVideoCodeGenerator.video.set(displayInLightbox: event.target.checked)

  updateInitialLink: (event) ->
    MSVVideoCodeGenerator.thumbnail.set(initialLink: event.target.value)

  updateSrc: (event) ->
    $('#video_origin_own').attr('checked', true)
    MSVVideoCodeGenerator.thumbnail.setAndPreloadSrc(event.target.value)

  updateThumbWidth: (event) ->
    MSVVideoCodeGenerator.thumbnail.setThumbWidth(parseInt(event.target.value))

  updateThumbHeight: (event) ->
    MSVVideoCodeGenerator.thumbnail.setThumbHeight(parseInt(event.target.value))

  resetThumbDimensions: (event) ->
    MSVVideoCodeGenerator.thumbnail.setThumbWidth(MSVVideoCodeGenerator.thumbnail.get('width'))

    false

  #
  # BINDINGS
  #
  render: ->
    $(@el).find('#lightbox_settings_fields').html this.template
      video: MSVVideoCodeGenerator.video
    $(@el).show()
    this.renderStatus()

    this

  renderExtraSettings: ->
    if MSVVideoCodeGenerator.thumbnail.get('initialLink') is 'image'
      $('#initial_link_image_extra').show()
    else
      $('#initial_link_image_extra').hide()
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
