class MSVVideoCode.Views.Settings extends Backbone.View
  template: JST['video_code/templates/settings']

  events:
    'change #poster_src':           'updatePosterSrc'
    'change #uid':                  'updateUid'
    'change #title':                'updateTitle'
    'change #width':                'updateWidth'
    'change #height':               'updateHeight'
    'click #keep_ratio':            'updateKeepRatio'
    'click a.reset':                'resetDimensions'
    'click input[name=autoresize]': 'updateAutoresize'
    'click #autoplay':              'updateAutoplay'

  initialize: ->
    this._initUIHelpers()
    @placeholder = $(@el).find('#video_settings_fields')

    _.bindAll this, 'render', 'renderWidth', 'renderHeight', 'renderPosterStatus'
    MSVVideoCode.poster.bind  'change',        this.renderPosterStatus
    MSVVideoCode.video.bind   'change:width',  this.renderWidth
    MSVVideoCode.video.bind   'change:height', this.renderHeight
    MSVVideoCode.video.bind   'change:uid',    this.render
    MSVVideoCode.video.bind   'change:title',  this.render
    MSVVideoCode.sources.bind 'change:src',    this.render

    this.render()

  #
  # EVENTS
  #
  updatePosterSrc: (event) ->
    $('#video_origin_own').prop('checked', true)
    MSVVideoCode.poster.setAndPreloadSrc(event.target.value)
    MSVVideoCode.video.set(testAssetsUsed: false)

  updateWidth: (event) ->
    MSVVideoCode.video.setWidth(event.target.value)

  updateHeight: (event) ->
    MSVVideoCode.video.setHeight(event.target.value)

  updateTitle: (event) ->
    MSVVideoCode.video.set(title: event.target.value)

  updateUid: (event) ->
    if MSVVideoCode.video.setUid(event.target.value)
      @UIDHelper.hideErrors()
    else
      @UIDHelper.renderError('src_invalid')

  updateKeepRatio: (event) ->
    MSVVideoCode.video.setKeepRatio(event.target.checked)
    this.render()

  resetDimensions: (event) ->
    MSVVideoCode.video.setKeepRatio(true)
    MSVVideoCode.video.setWidth(_.min([MSVVideoCode.video.get('sourceWidth'), 1920]))
    this.render()

    false

  updateAutoresize: (event) ->
    MSVVideoCode.video.set(autoresize: event.target.value)
    this.render()

  updateAutoplay: (event) ->
    MSVVideoCode.video.set(autoplay: event.target.checked)
    this.render()

  #
  # BINDINGS
  #
  render: ->
    @placeholder.html this.template()

    this

  renderWidth: ->
    $(@el).find("#width").val(MSVVideoCode.video.get('width'))

  renderHeight: ->
    $(@el).find("#height").val(MSVVideoCode.video.get('height'))

  renderPosterStatus: ->
    @posterHelper.hideErrors()

    return if MSVVideoCode.poster.srcIsEmpty()

    if !MSVVideoCode.poster.srcIsUrl()
      @posterHelper.renderError('src_invalid')
    else if !MSVVideoCode.poster.get('found')
      @posterHelper.renderError('not_found')
    else
      @posterHelper.renderValid()

  #
  # PRIVATE
  #
  _initUIHelpers: ->
    @posterHelper = new MSVVideoCode.Helpers.UIAssetHelper('poster')
    @UIDHelper    = new MSVVideoCode.Helpers.UIAssetHelper('uid')
