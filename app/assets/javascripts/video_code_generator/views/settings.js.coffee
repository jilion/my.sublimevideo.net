class MSVVideoCodeGenerator.Views.Settings extends Backbone.View
  template: JST['video_code_generator/templates/_settings']

  events:
    'change #poster_src':             'updatePosterSrc'
    'change #width':                  'updateWidth'
    'change #height':                 'updateHeight'
    'click #keep_ratio':              'updateKeepRatio'
    'click a.reset':                  'resetDimensions'
    'change #data_name':              'updateDataName'
    'change #data_uid':               'updateDataUID'
    'click input[name=autoresize]':   'updateAutoresize'
    'click #autoplay':                'updateAutoplay'

  initialize: ->
    @posterHelper = new MSVVideoCodeGenerator.Helpers.UIAssetHelper 'poster'

    _.bindAll this, 'render', 'renderWidth', 'renderHeight', 'renderPosterStatus'
    MSVVideoCodeGenerator.poster.bind  'change',          this.renderPosterStatus
    MSVVideoCodeGenerator.video.bind   'change:width',    this.renderWidth
    MSVVideoCodeGenerator.video.bind   'change:height',   this.renderHeight
    MSVVideoCodeGenerator.video.bind   'change:dataUID',  this.render
    MSVVideoCodeGenerator.video.bind   'change:dataName', this.render
    MSVVideoCodeGenerator.sources.bind 'change:src',      this.render

    this.render()

  #
  # EVENTS
  #
  updatePosterSrc: (event) ->
    MSVVideoCodeGenerator.poster.setAndPreloadSrc(event.target.value)
    MSVVideoCodeGenerator.video.set(testAssetsUsed: false)

  updateDataName: (event) ->
    MSVVideoCodeGenerator.video.set(dataName: event.target.value)

  updateDataUID: (event) ->
    MSVVideoCodeGenerator.video.set(dataUID: event.target.value)

  updateWidth: (event) ->
    newWidth = parseInt(event.target.value)
    MSVVideoCodeGenerator.video.setWidth(newWidth)

  updateHeight: (event) ->
    newHeight = parseInt(event.target.value)
    MSVVideoCodeGenerator.video.setHeight(newHeight)

  updateKeepRatio: (event) ->
    MSVVideoCodeGenerator.video.setKeepRatio(event.target.checked)
    this.render()

  resetDimensions: (event) ->
    MSVVideoCodeGenerator.video.setKeepRatio(true)
    MSVVideoCodeGenerator.video.setWidth(_.min([MSVVideoCodeGenerator.video.get('sourceWidth'), 852]))
    this.render()

    false

  updateAutoresize: (event) ->
    MSVVideoCodeGenerator.video.set(autoresize: event.target.value)
    this.render()

  updateAutoplay: (event) ->
    MSVVideoCodeGenerator.video.set(autoplay: event.target.checked)
    this.render()

  #
  # BINDINGS
  #
  render: ->
    $(@el).find('#video_settings_fields').html this.template
      poster: MSVVideoCodeGenerator.poster
      video: MSVVideoCodeGenerator.video
      sources: MSVVideoCodeGenerator.sources

    this

  renderWidth: ->
    $(@el).find("#width").attr(value: MSVVideoCodeGenerator.video.get('width'))

  renderHeight: ->
    $(@el).find("#height").attr(value: MSVVideoCodeGenerator.video.get('height'))

  renderPosterStatus: ->
    @posterHelper.hideErrors()

    return if MSVVideoCodeGenerator.poster.srcIsEmpty()

    if !MSVVideoCodeGenerator.poster.srcIsUrl()
      @posterHelper.renderError('src_invalid')
    else if !MSVVideoCodeGenerator.poster.get('found')
      @posterHelper.renderError('not_found')
    else
      @posterHelper.renderValid()
