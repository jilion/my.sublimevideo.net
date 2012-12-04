class MSVVideoCode.Views.Settings extends Backbone.View
  template: JST['video_code/templates/settings']

  events:
    'change #poster_src':           'updatePosterSrc'
    'change #width':                'updateWidth'
    'change #height':               'updateHeight'
    'click #keep_ratio':            'updateKeepRatio'
    'click a.reset':                'resetDimensions'
    'change #data_name':            'updateDataName'
    'change #data_uid':             'updateDataUID'
    'click input[name=autoresize]': 'updateAutoresize'
    'click #autoplay':              'updateAutoplay'

  initialize: ->
    @posterHelper = new MSVVideoCode.Helpers.UIAssetHelper 'poster'

    _.bindAll this, 'render', 'renderWidth', 'renderHeight', 'renderPosterStatus'
    MSVVideoCode.poster.bind  'change',          this.renderPosterStatus
    MSVVideoCode.video.bind   'change:width',    this.renderWidth
    MSVVideoCode.video.bind   'change:height',   this.renderHeight
    MSVVideoCode.video.bind   'change:dataUID',  this.render
    MSVVideoCode.video.bind   'change:dataName', this.render
    MSVVideoCode.sources.bind 'change:src',      this.render

    this.render()

  #
  # EVENTS
  #
  updatePosterSrc: (event) ->
    $('#video_origin_own').attr('checked', true)
    MSVVideoCode.poster.setAndPreloadSrc(event.target.value)
    MSVVideoCode.video.set(testAssetsUsed: false)

  updateDataName: (event) ->
    MSVVideoCode.video.set(dataName: event.target.value)

  updateDataUID: (event) ->
    MSVVideoCode.video.set(dataUID: event.target.value)

  updateWidth: (event) ->
    newWidth = parseInt(event.target.value)
    MSVVideoCode.video.setWidth(newWidth)

  updateHeight: (event) ->
    newHeight = parseInt(event.target.value)
    MSVVideoCode.video.setHeight(newHeight)

  updateKeepRatio: (event) ->
    MSVVideoCode.video.setKeepRatio(event.target.checked)
    this.render()

  resetDimensions: (event) ->
    MSVVideoCode.video.setKeepRatio(true)
    MSVVideoCode.video.setWidth(_.min([MSVVideoCode.video.get('sourceWidth'), 852]))
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
    $(@el).find('#video_settings_fields').html this.template
      video: MSVVideoCode.video

    this

  renderWidth: ->
    $(@el).find("#width").attr(value: MSVVideoCode.video.get('width'))

  renderHeight: ->
    $(@el).find("#height").attr(value: MSVVideoCode.video.get('height'))

  renderPosterStatus: ->
    @posterHelper.hideErrors()

    return if MSVVideoCode.poster.srcIsEmpty()

    if !MSVVideoCode.poster.srcIsUrl()
      @posterHelper.renderError('src_invalid')
    else if !MSVVideoCode.poster.get('found')
      @posterHelper.renderError('not_found')
    else
      @posterHelper.renderValid()