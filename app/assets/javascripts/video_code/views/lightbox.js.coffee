class MSVVideoCode.Views.Lightbox extends Backbone.View
  template: JST['video_code/templates/lightbox']

  events:
    'click #use_lightbox':            'updateDisplayInLightbox'
    'click input[name=initial_link]': 'updateInitialLink'
    'change #thumb_src':              'updateSrc'
    'change #thumb_width':            'updateThumbWidth'
    'change #thumb_height':           'updateThumbHeight'
    'click .reset':                   'resetThumbDimensions'

  initialize: ->
    this._initUIHelpers()
    @placeholder = $(@el).find('#lightbox_settings_fields')

    _.bindAll this, 'render', 'renderExtraSettings', 'renderThumbWidth', 'renderThumbHeight', 'renderStatus'
    MSVVideoCode.thumbnail.bind 'change:initialLink', this.renderExtraSettings
    MSVVideoCode.thumbnail.bind 'change:src',         this.renderStatus
    MSVVideoCode.thumbnail.bind 'change:found',       this.renderStatus
    MSVVideoCode.thumbnail.bind 'change:thumbWidth',  this.renderThumbWidth
    MSVVideoCode.thumbnail.bind 'change:thumbHeight', this.renderThumbHeight

    this.render()

  #
  # EVENTS
  #
  updateDisplayInLightbox: (event) ->
    MSVVideoCode.video.set(displayInLightbox: event.target.checked)

  updateInitialLink: (event) ->
    MSVVideoCode.thumbnail.set(initialLink: event.target.value)

  updateSrc: (event) ->
    $('#video_origin_own').prop('checked', true)
    MSVVideoCode.thumbnail.setAndPreloadSrc(event.target.value)

  updateThumbWidth: (event) ->
    MSVVideoCode.thumbnail.setThumbWidth(event.target.value)

  updateThumbHeight: (event) ->
    MSVVideoCode.thumbnail.setThumbHeight(event.target.value)

  resetThumbDimensions: (event) ->
    MSVVideoCode.thumbnail.setThumbWidth(MSVVideoCode.thumbnail.get('width'))

    false

  #
  # BINDINGS
  #
  render: ->
    @placeholder.html this.template()
    $(@el).show()
    this.renderStatus()

    this

  renderExtraSettings: ->
    if MSVVideoCode.thumbnail.get('initialLink') is 'image'
      $('#initial_link_image_extra').show()
    else
      $('#initial_link_image_extra').hide()
    this.renderStatus()

  renderThumbWidth: ->
    $("#thumb_width").val(MSVVideoCode.thumbnail.get('thumbWidth'))

  renderThumbHeight: ->
    $("#thumb_height").val(MSVVideoCode.thumbnail.get('thumbHeight'))

  renderStatus: ->
    @uiHelper.hideErrors()

    return if MSVVideoCode.thumbnail.get('initialLink') isnt 'image' or MSVVideoCode.thumbnail.srcIsEmpty()

    if !MSVVideoCode.thumbnail.srcIsUrl()
      @uiHelper.renderError('src_invalid')
    else if !MSVVideoCode.thumbnail.get('found')
      @uiHelper.renderError('not_found')
    else
      @uiHelper.renderValid()

  #
  # PRIVATE
  #
  _initUIHelpers: ->
    @uiHelper = new MSVVideoCode.Helpers.UIAssetHelper('thumb')
