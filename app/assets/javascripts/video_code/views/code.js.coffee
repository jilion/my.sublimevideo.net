class MSVVideoCode.Views.Code extends Backbone.View
  template: JST['video_code/templates/code']

  events:
    'click .get_the_code': 'render'

  initialize: ->
    this._initUIHelpers()

  #
  # BINDINGS
  #
  render: ->
    @popup = SublimeVideo.UI.Utils.openPopup
      class: 'popup'
      id: 'popup_code'
      content: this.template(videoTagHelper: @videoTagHelper, videoTagNoticesHelper: @videoTagNoticesHelper, settings: this._settings())

    false

  #
  # PRIVATE
  #
  _initUIHelpers: ->
    @videoTagHelper        = new MySublimeVideo.Helpers.VideoTagHelper(MSVVideoCode.video)
    @videoTagNoticesHelper = new MSVVideoCode.Helpers.VideoTagNoticesHelper(MSVVideoCode.video)

  _settings: ->
    s = {}
    s['player'] = { 'kit': MSVVideoCode.kits.selected.get('identifier') } unless MSVVideoCode.kits.defaultKitSelected()
    
    _.extend(s, MSVVideoCode.video.get('settings'))
    