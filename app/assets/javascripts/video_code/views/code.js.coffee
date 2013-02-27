class MSVVideoCode.Views.Code extends Backbone.View
  template: JST['video_code/templates/code']

  events:
    'click .get_the_code': 'render'

  initialize: ->
    @videoTagHelper        = new MySublimeVideo.Helpers.VideoTagHelper(MSVVideoCode.video)
    @videoTagNoticesHelper = new MSVVideoCode.Helpers.VideoTagNoticesHelper(MSVVideoCode.video)

  #
  # BINDINGS
  #
  render: ->
    settings = {}
    settings['player'] = { 'kit': MSVVideoCode.kits.selected.get('identifier') } unless MSVVideoCode.kits.defaultKitSelected()
    _.extend(settings, MSVVideoCode.video.get('settings'))

    @popup = SublimeVideo.UI.Utils.openPopup
      class: 'popup'
      id: 'popup_code'
      content: this.template(video: MSVVideoCode.video, videoTagHelper: @videoTagHelper, videoTagNoticesHelper: @videoTagNoticesHelper, settings: settings)

    false
