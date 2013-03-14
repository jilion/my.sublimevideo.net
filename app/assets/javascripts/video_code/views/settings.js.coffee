class MSVVideoCode.Views.Settings extends Backbone.View
  template: JST['video_code/templates/settings']

  initialize: ->
    this._listenToModelsEvents()
    this._initUIHelpers()
    this.render()

  #
  # EVENTS
  #
  events: ->
    'change #poster_src':           'updatePosterSrc'
    'change #uid':                  'updateUid'
    'change #title':                'updateTitle'
    'change #width':                'updateWidth'
    'change #height':               'updateHeight'
    'click #keep_ratio':            'updateKeepRatio'
    'click a.reset':                'resetDimensions'
    'click input[name=autoresize]': 'updateAutoresize'
    'click #autoplay':              'updateAutoplay'

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
  _listenToModelsEvents: ->
    this.listenTo(MSVVideoCode.video, {
      'change:width':  this._renderWidth
      'change:height': this._renderHeight
      'change:uid':    this._renderUid
      'change:title':  this._renderTitle
    })
    this.listenTo(MSVVideoCode.poster,  'change',     this._renderPosterStatus)
    this.listenTo(MSVVideoCode.sources, 'change:src', this.render)

  render: ->
    @$el.html this.template()

    this

  #
  # PRIVATE
  #
  _initUIHelpers: ->
    @posterHelper = new MSVVideoCode.Helpers.UIAssetHelper('poster')
    @UIDHelper    = new MSVVideoCode.Helpers.UIAssetHelper('uid')

  _renderWidth: ->
    this._renderField('width')

  _renderHeight: ->
    this._renderField('height')

  _renderUid: ->
    this._renderField('uid')

  _renderTitle: ->
    this._renderField('title')

  _renderPosterStatus: ->
    @posterHelper.hideErrors()

    return if MSVVideoCode.poster.srcIsEmpty()

    if !MSVVideoCode.poster.srcIsUrl()
      @posterHelper.renderError('src_invalid')
    else if !MSVVideoCode.poster.get('found')
      @posterHelper.renderError('not_found')
    else
      @posterHelper.renderValid()

  _renderField: (name)->
    this.$("##{name}").val(MSVVideoCode.video.get(name))
