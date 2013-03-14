class MSVVideoCode.Views.AssistantCode extends Backbone.View
  initialize: ->
    this._listenToModelsEvents()
    this._initUIHelpers()
    this.render()

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    _.each MSVVideoCode.playerModels, (model) =>
      this.listenTo(model, 'change', this.render)

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
