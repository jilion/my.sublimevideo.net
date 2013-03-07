class MSVVideoCode.Views.AssistantCode
  initialize: ->
    this._initUIHelpers()

    _.bindAll this, 'render'
    MSVVideoCode.kits.bind      'change',     this.render
    MSVVideoCode.video.bind     'change',     this.render
    MSVVideoCode.poster.bind    'change:src', this.render
    MSVVideoCode.sources.bind   'change',     this.render
    MSVVideoCode.thumbnail.bind 'change',     this.render

  render: ->
    settings = {}
    settings['player'] = { 'kit': MSVVideoCode.kits.selected.get('identifier') } unless MSVVideoCode.kits.defaultKitSelected()
    _.extend(settings, MSVVideoCode.video.get('settings'))

    $('#video_code_for_assistant_summary').val(@videoTagHelper.generatePlayerCode({ id: MSVVideoCode.video.get('uid') or 'video1', settings: settings, kitReplacement: false }))

  #
  # PRIVATE
  #
  _initUIHelpers: ->
    @videoTagHelper = new MySublimeVideo.Helpers.VideoTagHelper(MSVVideoCode.video)
